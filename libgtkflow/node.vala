/********************************************************************
# Copyright 2014 Daniel 'grindhold' Brendle
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

/**
 * Flowgraphs for Gtk
 */
namespace GtkFlow {
    private struct DockRendererMapping {
        public GFlow.Dock dock;
        public DockRenderer renderer;
    }

    /**
     * Represents an element that can generate, process or receive data
     * This is done by adding Sources and Sinks to it. The inner logic of
     * The node can be represented towards the user as arbitrary Gtk widget.
     */
    private class Node : Gtk.Bin {
        // Determines the space between the title and the first dock (y-axis)
        // as well as the space between the title and the close-button if any (x-axis)

        public GFlow.Node gnode {public get; private set; default = null;}

        public NodeView? node_view {get; set; default=null;}

        public NodeRenderer? node_renderer {get; set; default=null;}

        private List<DockRendererMapping?> dock_renderers = new List<DockRendererMapping?>();

        private Gtk.Allocation node_allocation;

        private List<Gtk.Widget> children = new List<Gtk.Widget>();

        public Node (GFlow.Node n) {
            this.gnode = n;
            foreach (GFlow.Dock d in this.gnode.get_sources())
                this.register_dock(d);
            foreach (GFlow.Dock d in this.gnode.get_sinks())
                this.register_dock(d);
            this.gnode.source_added.connect((s)=>{this.register_dock(s);});
            this.gnode.sink_added.connect((s)=>{this.register_dock(s);});
            this.gnode.source_removed.connect((s)=>{this.unregister_dock(s);});
            this.gnode.sink_removed.connect((s)=>{this.unregister_dock(s);});
            this.node_allocation = {0,0,0,0};
            this.node_renderer = new DefaultNodeRenderer(this);
            this.notify["node-view"].connect(()=>{this.render_all();});
            this.set_border_width(this.node_renderer.resize_handle_size);
            this.recalculate_size();
        }

        public void render_all() {
            if (this.node_renderer != null)
                this.node_renderer.update_name_layout();
            foreach(DockRendererMapping drm in this.dock_renderers)
                if (drm.renderer != null)
                    drm.renderer.update_name_layout();
        }

        private void register_dock(GFlow.Dock d) {
            DefaultDockRenderer dr = new DefaultDockRenderer(this, d);
            DockRendererMapping m = {d,dr};
            this.dock_renderers.append(m);
            dr.update_name_layout();
        }

        public DockRendererMapping? get_dock_renderer_mapping(GFlow.Dock d) {
            foreach (DockRendererMapping m in this.dock_renderers) {
                if (m.dock == d)
                    return m;
            }
            return null;
        }

        private void unregister_dock(GFlow.Dock d) {
            DockRendererMapping? m = this.get_dock_renderer_mapping(d);
            if (m != null) {
                this.dock_renderers.remove(m);
                //m.free();
            }
        }

        public unowned Gtk.Widget? get_first_child() {
            if (this.children.length() > 0)
                return this.children.nth_data(0);
            else
                return null;
        }

        public Node.with_child(GFlow.Node n, Gtk.Widget c) {
            this(n);
            this.add(c);
            this.show_all();
            this.recalculate_size();
            this.node_view.queue_draw();
        }

        public void set_node_allocation(Gtk.Allocation alloc) {
            if (alloc.width < (int)this.node_renderer.get_min_width())
                alloc.width = (int)this.node_renderer.get_min_width();
            if (alloc.height < (int)this.node_renderer.get_min_height())
                alloc.height = (int)this.node_renderer.get_min_height();
            this.node_allocation = alloc;
        }

        public void set_position(int x, int y) {
            this.node_allocation.x = x;
            this.node_allocation.y = y;
            this.node_view.queue_draw();
        }

        public void get_node_allocation(out Gtk.Allocation alloc) {
            alloc = Gtk.Allocation();
            alloc.x = this.node_allocation.x;
            alloc.y = this.node_allocation.y;
            alloc.width = this.node_allocation.width;
            alloc.height = this.node_allocation.height;
        }

        public override void add(Gtk.Widget w) {
            w.set_parent(this);
            this.children.append(w);
            base.add(w);
        }

        public override void remove(Gtk.Widget w) {
            w.unparent();
            this.children.remove(w);
            base.remove(w);
        }

        public new void set_border_width(uint border_width) {
            int nr = this.node_renderer.resize_handle_size;
            if (border_width < nr) {
                warning("Cannot set border width smaller than %d", nr);
                return;
            }
            base.set_border_width(border_width);
            this.recalculate_size();
            this.node_view.queue_draw();
        }

        /**
         * Checks if the node needs to be resized in order to fill the minimum
         * size requirements
         */
        public void recalculate_size() {
            Gtk.Allocation alloc;
            this.get_node_allocation(out alloc);
            uint mw = this.node_renderer.get_min_width();
            uint mh = this.node_renderer.get_min_height();
            if (mw > alloc.width)
                alloc.width = (int)mw;
            if (mh > alloc.height)
                alloc.height = (int)mh;
            this.set_node_allocation(alloc);
        }
    }
}
