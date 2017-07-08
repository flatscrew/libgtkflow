/********************************************************************
# Copyright 2014-2017 Daniel 'grindhold' Brendle, 2015 Daniel Espinosa <esodan@gmail.com>
#
# This file is part of libgflow.
#
# libgflow is free software: you can redistribute it and/or
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
     * This class represents an endpoint of a node. These endpoints can be
     * connected in order to let them exchange data. The data contained
     * in this endpoint is stored as GLib.Value. Only Docks that contain
     * data with the same VariantType can be interconnected.
     */
    public interface Dock : Object {
        /**
         * The name that will be rendered for this dock
         */
        public abstract string? name { get; set; }

        /**
         * The string rendered as typehint for this dock.
         * If this string is "" and the show_type is set to true
         * libgflow will attempt to determine the type of this
         * dock and display it, but it produces nicer results to set
         * them manually.
         */
        public abstract string? typename { get; set; }

        /**
         * Determines whether this dock is highlighted
         * this is usually triggered when the mouse hovers over it
         */
        public abstract bool highlight { get; set; }

        /**
         * Determines whether this dock is active
         */
        public abstract bool active { get; set; }

        /**
         * A reference to the node this Dock resides in
         */
        public abstract weak Node? node { get; set; }

        /**
         * The value that is stored in this Dock
         * TODO: Consider that this value could be a stream not a fixed value
         */
        public abstract GLib.Value? val { get; set; }

        /**
         * The initial value that has been set to this dock
         * The dock will be set to this value when it is rendered
         * invalid
         */
        public abstract GLib.Value? initial { get; }

        /**
         * This variable is true if the dock currently
         * holds a valid value
         */
        public abstract bool valid { get; }

        /**
         * This signal is being triggered, when there is a connection being established
         * from or to this Dock.
         */
        public signal void linked (Dock d);

        /**
         * This signal is being triggered, when there is a connection being established
         * from or to this Dock.
         */
        public signal void unlinked (Dock d);

        /**
         * Triggers when the value of this dock changes
         */
        public signal void changed ();

        /**
         * Render this dock invalid. That means that entities that request to get
         * the value will be provided with an invalid-Exception
         */
        public abstract void invalidate ();

        /**
         * Implementations should return true if this dock has at least one
         * connection to another dock
         */
        public abstract bool is_linked ();

        /**
         * Implementations should return true if this dock is connected
         * to the supplied dock
         */
        public abstract bool is_linked_to (Dock dock);

        /**
         * Connect this {@link Dock} to other {@link Dock}
         */
        public abstract void link (Dock dock) throws GLib.Error;
        /**
         * Disconnect this {@link Dock} from other {@link Dock}
         */
        public abstract void unlink (Dock dock) throws GLib.Error;
        /**
         * Disconnect this {@link Dock} from all {@link Dock}s it is connected to
         */
        public abstract void unlink_all () throws GLib.Error;

        /**
         * Tries to resolve this Dock's value-type to a displayable string
         */
        public virtual string determine_typestring () {
            if (this.val != null)
                return this.val.type().name();
            else
                return "";
        }

        /**
         * Returs true if this and the supplied dock have
         * same type
         */
        public virtual bool has_same_type (Dock other) {
            return this.val.type_name() == other.val.type_name();
        }
    }
}
