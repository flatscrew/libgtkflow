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
     * Represents an element that can generate, process or receive data
     * This is done by adding Sources and Sinks to it. The inner logic of
     * The node can be represented towards the user as arbitrary Gtk widget.
     */
    public class SimpleNode : Object, Node
    {
        private List<Source> sources = new List<Source>();
        private List<Sink> sinks = new List<Sink>();

        /**
         * This SimpleNode's name
         */
        public string name { get; set; default="SimpleNode";}

        /**
         * Add the given {@link Source} to this SimpleNode
         */
        public void add_source(Source s) throws NodeError {
            if (s.node != null)
                throw new NodeError.DOCK_ALREADY_BOUND_TO_NODE("This Source is already bound");
            if (this.sources.index(s) != -1)
                throw new NodeError.ALREADY_HAS_DOCK("This node already has this source");
            sources.append(s);
            s.node = this;
            source_added (s);
        }
        /**
         * Add the given {@link Sink} to this SimpleNode
         */
        public void add_sink (Sink s) throws NodeError {
            if (s.node != null)
                throw new NodeError.DOCK_ALREADY_BOUND_TO_NODE("This Sink is already bound" );
            if (this.sinks.index(s) != -1)
                throw new NodeError.ALREADY_HAS_DOCK("This node already has this sink");
            sinks.append(s);
            s.node = this;
            sink_added (s);
        }

        /**
         * Remove the given {@link Source} from this SimpleNode
         */
        public void remove_source(Source s) throws NodeError {
            if (this.sources.index(s) == -1)
                throw new NodeError.NO_SUCH_DOCK("This node doesn't have this source");
            sources.remove(s);
            s.node = null;
            source_removed (s);
        }

        /**
         * Remove the given {@link Sink} from this SimpleNode
         */
        public void remove_sink(Sink s) throws NodeError {
            if (this.sinks.index(s) == -1)
                throw new NodeError.NO_SUCH_DOCK("This node doesn't have this sink");
            sinks.remove(s);
            s.node = null;
            sink_removed (s);
        }

        /**
         * Returns true if the given {@link Sink} is one of this SimpleNode's Sinks.
         */
        public bool has_sink(Sink s) {
            return this.sinks.index(s) != -1;
        }

        /**
         * Returns true if the given {@link Source} is one of this SimpleNode's Sources.
         */
        public bool has_source(Source s) {
            return this.sources.index(s) != -1;
        }

        /**
         * Returns true if the given {@link Dock} is one of this SimpleNode's Docks.
         */
        public bool has_dock(Dock d) {
            if (d is Source)
                return this.has_source(d as Source);
            else
                return this.has_sink(d as Sink);
        }

        /**
         * Searches this SimpleNode's {@link Dock}s for a Dock with the given name.
         * If there is any, it will be returned. Else, null will be returned
         */
        public Dock? get_dock (string name) {
            foreach (Sink s in this.sinks)
                if (s.name == name)
                    return s;
            foreach (Source s in this.sources)
                if (s.name == name)
                    return s;
            return null;
        }

        /**
         * Returns the sources of this node
         */
        public unowned List<Source> get_sources() {
            return this.sources;
        }

        /**
         * Returns the sinks of this node
         */
        public unowned List<Sink> get_sinks() {
            return this.sinks;
        }

        /**
         * This method checks whether a connection from the given from-Node
         * to this Node would lead to a recursion in the direction source -> sink
         */
        public bool is_recursive_forward(Node from, bool initial=true) {
            if (!initial && this == from)
                return true;
            foreach (Source source in this.get_sources()) {
                foreach (Sink sink in source.sinks) {
                    if (sink.node.is_recursive_forward(from, false))
                        return true;
                }
            }
            return false;
        }

        /**
         * This method checks whether a connection from the given from-Node
         * to this Node would lead to a recursion in the direction sink -> source
         */
        public bool is_recursive_backward(Node from, bool initial=true) {
            if (!initial && this == from)
                return true;
            foreach (Sink sink in this.sinks) {
                if (sink.source != null) {
                    if (sink.source.node.is_recursive_backward(from, false))
                        return true;
                }
            }
            return false;
        }

        /**
         * Disconnect all connections from and to this node
         */
        public void disconnect_all() {
            foreach (Source s in this.sources) {
                try {
                    s.disconnect_all();
                } catch (GLib.Error e) {
                    warning("Could not disconnect source %s from node %s", s.name, this.name);
                }
            }
            foreach (Sink s in this.sinks) {
                try {
                    s.disconnect_all();
                } catch (GLib.Error e) {
                    warning("Could not disconnect sink %s from node %s", s.name, this.name);
                }
            }
        }
  }
}
