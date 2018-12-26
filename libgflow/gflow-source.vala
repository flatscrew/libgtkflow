/********************************************************************
# Copyright 2014-2019 Daniel 'grindhold' Brendle, 2015 Daniel Espinosa <esodan@gmail.com>
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
     * The Source is a special Type of Dock that provides data.
     * A Source may be used by multitude of Sinks as a source of data.
     */
    public interface Source : Object, Dock {
        /**
         * Returns the sinks that this source is connected to
         */
        public abstract List<Sink> sinks { get; }

        /**
         * The value that is stored in this Dock
         * TODO: Consider that this value could be a stream not a fixed value
         */
        public abstract GLib.Value? val { get; set; }
    }
}
