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
     * A simple implementation of {@link GFlow.Sink}.
     */
    public class SimpleSink : Object, Dock, Sink {
        // Dock interface
        protected GLib.Value? _val = null;
        protected GLib.Value? _initial = null;
        protected bool _valid = false;

        private string? _name = null;
        /**
         * This SimpleSink's displayname
         */
        public string? name { 
            get { return this._name; }
            set { this._name = value; }
        }
        public string? _typename = null;
        /**
         * This SimpleSink's typestring
         */
        public string? typename {
            get { return this._typename; }
            set { this._typename = value; }
        }
        /**
         * Indicates whether this Sink should be rendered highlighted
         */
        public bool highlight { get; set; default = false; }
        /**
         * Indicates whether this Sink should be rendered active
         */
        public bool active {get; set; default=false;}
        /**
         * A reference to the {@link Node} that this SimpleSink resides in
         */
        public weak Node? node { get; set; }
        /**
         * The value that this SimpleSink was initialized with
         */
        public GLib.Value? initial { get { return _initial; } }
        /**
         * If this value is true, the value of the SimpleSource is currently valid
         */
        public bool valid { get { return _valid; } }
        // Sink Interface
        protected weak Source? _source;
        /**
         * The {@link Source} that this SimpleSink is currently connected to
         */
        public weak Source? source {
            get{
                return this._source;
            }
        }
        /**
         * The value that this SimpleSink holds
         */
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

        /**
         * Creates a new SimpleSink with the given initial {@link GLib.Value}
         */
        public SimpleSink (GLib.Value? initial) {
          _val = _initial = initial;
        }

        /**
         * Returns true if this sink is connected to a source
         */
        public bool is_connected() {
            return this.source != null;
        }

        /**
         * Returns true if this SimpleSink is connected to the given {@link Dock}
         */
        public bool is_connected_to (Dock dock) { // FIXME Use more logic to know Source type, value or name
            if (!(dock is Source)) return false;
            return this.source ==  ((Source) dock);
        }

        /**
         * Declare the value that this SimpleSink holds invalid. Any call to
         * {@link SimpleSink.get_value} will result in a exception until this
         * SimpleSink's {@link Source} supplies a new valid value
         */
        public void invalidate () {
            this._valid = false;
            this.changed ();
        }

        /**
         * Disconnect from the given {@link Dock}
         */
        public new void disconnect (Dock dock) throws GLib.Error {
          if (!this.is_connected_to (dock)) return;
          if (dock is Source) {
            if (source != null) {
              source.disconnect (this);
            }
            _source = null;
            _valid = false;
            dock.changed.disconnect (this.do_source_changed);
            changed();
            disconnected (dock);
          }
        }

        private void do_source_changed() {
            val = _source.val;
        }

        /**
         * Connect to the given {@link Dock}
         */
        public new void connect (Dock dock) throws GLib.Error {
            if (this.is_connected_to (dock)) return;
            if (dock is Source) {
                if (source != null) ((Dock) source).disconnect (this);
                _source = (Source) dock;
                val = _source.val;
                if (!_source.valid)
                    _valid = false;
                changed();
                dock.connect (this);
                _source.changed.connect (this.do_source_changed);
                connected (dock);
            }
        }

        /**
         * Disconnect from any {@link Dock} that this SimpleSink is connected to
         */
        public new void disconnect_all() throws GLib.Error {
            if (this.source != null)
                this.disconnect(this.source);
        }

        /**
         * Retrieve the {@link GLib.Value} that this SimpleSource currently holds.
         * If the value is invalid, an exception will be thrown.
         */
        public Value? get_value() throws NodeError {
            if (!this.valid) {
                throw new NodeError.INVALID("This sink does not hold a valid value");
            } else {
                return _val;
            }
        }
    }
}
