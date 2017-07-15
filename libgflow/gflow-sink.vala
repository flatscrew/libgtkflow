/********************************************************************
# Copyright 2014-2017 Daniel 'grindhold' Brendle, 2015 Daniel Espinosa <esodan@gmail.com>
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
     * A Sink is a special Type of Dock that receives data from
     * a source in order to let it either 
     */
    public interface Sink : Object, Dock {
        /**
         * Returns the sinks that this source is connected to
         */
        public abstract List<Source> sources { get; }

        /**
         * Disconnects the Sink from all {@link Source}s that supply
         * it with data.
         */
        public virtual void unlink_all () throws GLib.Error
        {
            foreach (Source s in this.sources)
                this.unlink (s);
        }
    }
}
