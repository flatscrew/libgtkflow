/********************************************************************
# Copyright 2014-2022 Daniel 'grindhold' Brendle
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

namespace GtkFlow {
    public interface Layout {
        /**
         * Rearranges the Nodes on a nodeview according to the
         * algorithm that implements this method
         */
        internal abstract void arrange(List<unowned Node> nodes);
    }

    /**
     * Spring-Simulation mechanism autolayouter
     *
     * THIS FEATURE IS VERY EXPERIMENTAL. USE AT YOUR OWN RISK.
     * IT WILL VERY LIKELY SEGFAULT AND MAYBE RID YOUR ACCOUNT
     * OF ALL YOUR METICUOUSLY COLLECTED FLURBOS.
     */
    public class ForceLayout : GLib.Object, Layout {
        /**
         * Desired spacing between nodes in pixels
         */
        private const double SPACING = 30;
        /**
         * How often the forces will be calculated
         */
        private const uint RUNS = 50;

        private NodeView node_view = null;

        /**
         * Rearranges the Nodes on a nodeview according to simulated
         * behaviour of mechanical springs
         */
        internal void arrange(List<unowned Node> nodes) {
            this.detect_nodeview(nodes);

            var forces = new HashTable<Node, Point?>(direct_hash, direct_equal);

            for (int i = 0; i < RUNS; i++) {
                foreach (Node from in nodes) {
                    forces[from] = {0,0};
                    foreach (Node to in nodes) {
                        var force = this.calculate_force(from, to);
                        forces[from].x += force.x;
                        forces[from].y += force.y;
                    }
                }
                foreach (Node from in nodes) {
                    var alloc = this.node_view.get_node_allocation(from.gnode);
                    alloc.x += forces[from].x;
                    alloc.y += forces[from].y;
                    this.node_view.set_node_position(from.gnode, alloc.x, alloc.y);
                }
            }
            int min_x = 0;
            int min_y = 0;
            foreach (Node node in nodes) {
                var alloc = this.node_view.get_node_allocation(node.gnode);
                min_x = int.min(alloc.x, min_x);
                min_y = int.min(alloc.y, min_y);
            }
            foreach (Node node in nodes) {
                var alloc = this.node_view.get_node_allocation(node.gnode);
                alloc.x += min_x.abs();
                alloc.y += min_y.abs();
                this.node_view.set_node_position(node.gnode, alloc.x, alloc.y);
            }
        }

        /**
         * Detects the nodeview that has to be written to
         * And throws an error if the given Node List contains more
         * than one or no nodeview
         */
        private void detect_nodeview (List<unowned Node> nodes) {
            foreach (Node node in nodes) {
                if (node.node_view == null) {
                    warning("Node given to layouter is not attached to nodeview");
                    continue;
                }
                if (this.node_view == null)
                    this.node_view = node.node_view;
                else if (this.node_view != node.node_view)
                    warning("Nodes given to this layouter do not belong to the same NodeView");
            }
            if (this.node_view == null)
                error ("No nodeview could be detected");
        }

        /**
         * Calculates the ideal distance between the two nodes
         * of the Connection and the angle of the direct line
         * that would connect them.
         */
        private Point calculate_force(Node from, Node to) {
            if (from == to)
                return {0,0};

            var alloc_from = this.node_view.get_node_allocation(from.gnode);
            var alloc_to = this.node_view.get_node_allocation(to.gnode);

            // This is a relative viewpoint so we dont need acutal positions
            Point from_middle = {alloc_from.width/2,alloc_from.height/2};
            Point to_middle = {alloc_to.width/2,alloc_to.height/2};

            // Calculate the desired distance
            double x_dist = (double)from_middle.x + (double)to_middle.x;
            double y_dist = (double)from_middle.y + (double)to_middle.y;
            double desired_distance = SPACING + Math.sqrt(Math.pow(x_dist, 2.0) + Math.pow(y_dist, 2.0));

            // This is an absolute viewpoint so we need acutal positions
            from_middle = {alloc_from.x + alloc_from.width/2, alloc_from.y + alloc_from.height/2};
            to_middle = {alloc_to.x + alloc_to.width/2, alloc_to.y + alloc_to.height/2};

            // Calculate the actual distance
            double x_dist_real = (double)to_middle.x - (double)from_middle.x;
            double y_dist_real = (double)to_middle.y - (double)from_middle.y;
            double real_distance = SPACING + Math.sqrt(Math.pow(x_dist_real, 2.0) + Math.pow(y_dist_real, 2.0));

            // Calculate attractive force
            double force = 0d;
            if (from.gnode.is_neighbor(to.gnode) && real_distance > desired_distance) {
                force = Math.pow(real_distance, 2.0) / desired_distance;
                force *= 0.1 * double.max(real_distance/desired_distance -1, 0);
            } else {
                force = - Math.pow(desired_distance, 2.0) / real_distance;
                force *= 0.1 * double.max(desired_distance/real_distance -1, 0);
            }

            // Calculate x / y force components
            double f_x = 1.5*((force / 2.0) / real_distance) * x_dist_real;
            double f_y = 0.5*((force / 2.0) / real_distance) * y_dist_real;

            // Write out new allocation
            return {(int)Math.round(f_x), (int)Math.round(f_y)};
        }
    }
}
