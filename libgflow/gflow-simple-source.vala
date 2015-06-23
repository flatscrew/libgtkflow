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
     * A simple implementation of {@link GtkFlow.Source}.
     */
    public class SimpleSource : Object, Dock, Source {
        // Dock interface
        protected GLib.Value? _val;
        protected GLib.Value? _initial;
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
        public bool highlight { get; set; }
        public bool active {get; set; default=false;}
        public weak Node? node { get; set; }
        public GLib.Value? val {
          get { return _val; }
          set {
            if (!_val.holds (value.type ())) return;
            _val = value;
            changed ();
          }
        }
        public SimpleSource (GLib.Value initial) {
          _initial = initial;
          _val = _initial;
        }
        public GLib.Value? initial { get { return _initial; } }
        public bool valid { get { return _valid; } }
        // Source interface

        // FIXME This should not be set by users is a matter of test to know if source should work
        public new void set_valid() {
            this._valid = true;
        }
        /**
         * Returns true if this Source is connected to the given Sink
         */
        public bool is_connected_to (Dock dock) {
            return dock.is_connected_to (this);
        }

        /**
         * All {@link GFlow.Source} object are connected by default, because they
         * just update its value and any {@link GFlow.Sink} connected to it catch
         * any change.
         */
        public bool is_connected () {
            return true;
        }
        /**
         * Mark this {@link Source} as invalid.
         */
        public void invalidate () {
            _valid = false;
        }
// FIXME: This operation are valid just for GFlow.Sink consider move to Sink interface from Dock
        public new void disconnect (Dock dock) throws GLib.Error
        {
          dock.disconnect (this);
          dock.connected.disconnect (connection_event);
          dock.disconnected.disconnect (disconnection_event);
        }
        public new void connect (Dock dock) throws GLib.Error
        {
          dock.connected.connect (connection_event);
          dock.disconnected.connect (disconnection_event);
          dock.connect (this);
        }
        public void disconnect_all () throws GLib.Error
        {
          return;
        }
        private void connection_event (Dock dock)
        {
          if (dock == ((Dock) this))
            connected (dock);
        }
        private void disconnection_event (Dock dock)
        {
          if (dock == ((Dock) this)) {
            disconnected (dock);
          }
        }
    }
}
