/********************************************************************
# Copyright 2014 Daniel 'grindhold' Brendle, 2015 Daniel Espinosa <esodan@gmail.com>
#
# This file is part of libgtkflow.
#
# libgtkflow is free software: you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later
# version.
#
# libgtkflow is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with libgtkflow.
# If not, see http://www.gnu.org/licenses/.
*********************************************************************/

namespace GFlow {
    /**
     * A simple implementation of {@link GtkFlow.Sink}.
     */
    public class SimpleSink : Object, Dock, Sink {
        // Dock interface
        protected GLib.Value? _val = null;
        protected GLib.Value? _initial = null;
        protected bool _valid = false;

        private string? _name = null;
        public string? name { 
            get { return this._name; }
            set { this._name = value; }
        }
        public string? _typename = null;
        public string? typename {
            get { return this._typename; }
            set { this._typename = value; }
        }
        public bool highlight { get; set; default = false; }
        public bool active {get; set; default=false;}
        public weak Node? node { get; set; }
        public GLib.Value? initial { get { return _initial; } }
        public bool valid { get { return _valid; } }
        // Sink Interface
        protected weak Source? _source;
        public weak Source? source {
            get{
                return this._source;
            }
        }
        public GLib.Value? val {
          get {
            return _val;
          }
          set {
            if (!_val.holds (value.type ())) return;
            _val = value;
            this._valid = true;
            // FIXME: This properly is read-only then may let implementators to define how "Change a Value"
            changed ();
          }
        }

        public SimpleSink (GLib.Value? initial) {
          _val = _initial = initial;
        }

        /**
         * Returns true if this sink is connected to a source
         */
        public bool is_connected() {
            return this.source != null;
        }

        public bool is_connected_to (Dock dock) { // FIXME Use more logic to know Source type, value or name
            if (!(dock is Source)) return false;
            return this.source ==  ((Source) dock);
        }

        public void invalidate () {
            this._valid = false;
            this.changed ();
        }

        public new void disconnect (Dock dock) throws GLib.Error {
          if (!this.is_connected_to (dock)) return;
          if (dock is Source) {
            if (source != null) {
              source.disconnect (this);
            }
            _source = null;
            _valid = false;
            changed();
            disconnected (dock);
          }
        }
        public new void connect (Dock dock) throws GLib.Error
        {
            GLib.message ("At Sink Connect");
          if (dock is SimpleSource) {
            GLib.message ("Dock is SimpleSource to Connect");
            if (!val.holds (dock.val.type ())) {
            GLib.message ("Incompatible source");
              throw new DockError.CANT_CONNECT ("Can't connect. Dock is incompatible"); }
          }
            GLib.message ("Check if already connected Connecting Source..");
          if (dock.is_connected_to (this)) return;
          if (dock is Source) {
            if (source != null) ((Dock) source).disconnect (this);
            GLib.message ("Saving Source..");
            _source = (Source) dock;
            GLib.message ("Connecting Dock to this Sink..");
            dock.connect (this);
            _source.changed.connect (() =>{
              val = _source.val;
            });
            connected (dock);
          }
        }
// FIXME: This method is just useful for GFlow.Node objects no more than one connection is valid a given time
        public void disconnect_all () throws GLib.Error
        {
          disconnect (source);
        }
        // FIXME This oeverrides Dock.changed signals and set a value but this should not be the case
        // FIXME when change_value is callled it sets its value and send this signal
/*        public virtual signal void changed (GLib.Value v) {
            this.val = v;
        }*/

    }
}
