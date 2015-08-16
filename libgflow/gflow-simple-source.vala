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
     * A simple implementation of {@link GFlow.Source}.
     */
    public class SimpleSource : Object, Dock, Source {
        // Dock interface
        protected GLib.Value? _val;
        protected GLib.Value? _initial;
        protected bool _valid = false;

        private string? _name = null;
        /**
         * This SimpleSource's displayname
         */
        public string? name { 
            get { return this._name; }
            set { this._name = value; }
        }
        /**
         * This SimpleSource's typestring
         */
        public string? _typename = null;
        public string? typename {
            get { return this._typename; }
            set { this._typename = value; }
        }
        /**
         * Indicates whether this Source should be rendered highlighted
         */
        public bool highlight { get; set; }
        /**
         * Indicates whether this Source should be rendered active
         */
        public bool active {get; set; default=false;}
        /**
         * A reference to the {@link Node} that this SimpleSource resides in
         */
        public weak Node? node { get; set; }
        /**
         * The value that this SimpleSource holds
         */
        public GLib.Value? val {
          get { return _val; }
          set {
            if (!_val.holds (value.type ())) return;
            _val = value;
            changed ();
          }
        }
        /**
         * Creates a new SimpleSource. Supply an arbitrary {@link GLib.Value}. This
         * initial value's type will determine this SimpleSource's type.
         */
        public SimpleSource (GLib.Value initial) {
          _initial = initial;
          _val = _initial;
        }
        /**
         * The value that this SimpleSource was initialized with
         */
        public GLib.Value? initial { get { return _initial; } }
        /**
         * If this value is true, the value of the SimpleSource is currently valid
         */
        public bool valid { get { return _valid; } }
        // Source interface
        private List<Sink> _sinks = new List<Sink> ();
        /**
         * The {@link Sink}s that this SimpleSource is connected to
         */
        public List<Sink> sinks { get { return _sinks; } }

        /**
         * Connects this SimpleSource to the given {@link Sink}. This will
         * only succeed if both {@link Dock}s are of the same type. If this
         * is not the case, an exception will be thrown
         */
        protected void add_sink (Sink s) throws Error
        {
            if (this.val.type() != s.val.type()) {
                throw new NodeError.INCOMPATIBLE_SINKTYPE(
                    "Can't connect. Sink has type %s while Source has type %s".printf(
                        s.val.type().name(), this.val.type().name()
                    )
                );
            }
            this._sinks.append (s);
            if (this.valid) {
                s.val = this.val;
            }
        }

        /**
         * Destroys the connection between this SimpleSource and the given {@link Sink}
         */
        protected void remove_sink (Sink s) throws GLib.Error
        {
            if (this._sinks.index(s) != -1)
                this._sinks.remove(s);
            if (s.is_linked_to(this))
                s.unlink (this);
            this.unlinked(s);
        }

        /**
         * Manually set this node to be valid. Use this if you initialized the SimpleSource
         * with a value that you really want to be it's first value.
         */
        public new void set_valid() {
            this._valid = true;
        }
        /**
         * Returns true if this Source is connected to the given Sink
         */
        public bool is_linked_to (Dock dock) {
            if (!(dock is Sink)) return false;
            return this._sinks.index((Sink) dock) != -1;
        }

        /**
         * Returns true if this Source is connected to one or more Sinks
         */
        public bool is_linked () {
            return this.sinks.length () > 0;
        }

        /**
         * Declare the value that this SimpleSource holds invalid. Subsequently
         * All {@link Sink}s that are connected to this SimpleSource will be invalidated.
         */
        public void invalidate () {
            _valid = false;
            foreach (Sink s in this.sinks)
                s.invalidate();
        }

        /**
         * Disconnect from the given {@link Dock}
         */
        public new void unlink (Dock dock) throws GLib.Error
        {
          if (!this.is_linked_to (dock)) return;
          if (dock is Sink) {
            remove_sink ((Sink) dock);
            if (sinks.length () == 0) unlinked (dock);
          }
        }

        /**
         * Connect to the given {@link Dock}
         */
        public new void link (Dock dock) throws GLib.Error
        {
          if (dock is Sink) {
            if (this.is_linked_to (dock)) return;
            add_sink ((Sink) dock);
            dock.link (this);
            linked (dock);
          }
        }

        /**
         * Disconnect from any {@link Dock} that this SimplesSource is connected to
         */
        public new void unlink_all () throws GLib.Error {
            foreach (Sink s in this._sinks)
                if (s != null)
                    this.unlink(s);
        }

        /**
         * Set the value of this SimpleSource
         */
        public void set_value (GLib.Value v) throws GLib.Error
        {
            if (this.val.type() != v.type())
                throw new NodeError.INCOMPATIBLE_VALUE(
                    "Cannot set a %s value to this %s Source".printf(
                        v.type().name(),this.val.type().name())
                );
            this.val = v;
            this._valid = true;
            changed ();
        }
    }
}
