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

        private List<DockRenderer?> dock_renderers = new List<DockRenderer?>();

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
            this.node_renderer.size_changed.connect(()=>{this.render();});
            this.node_renderer.child_redraw.connect((ch, cr)=>{this.propagate_draw(ch,cr);});
            this.gnode.notify["name"].connect(()=>{
                this.node_renderer.update_name_layout(this.gnode.name);
            });
            this.set_border_width(this.node_renderer.resize_handle_size);
            this.render();
        }

        public void render() {
            this.recalculate_size();
            if (this.node_view != null) {
                this.node_view.queue_draw();
            }
        }

        public void render_all() {
            if (this.node_renderer != null)
                this.node_renderer.update_name_layout(this.gnode.name);
            foreach(DockRenderer dr in this.dock_renderers)
                if (dr != null) {
                    bool show_types = this.node_view != null ? this.node_view.show_types : false;
                    dr.update_name_layout(show_types);
                }
        }

        private void register_dock(GFlow.Dock d) {
            DefaultDockRenderer dr = new DefaultDockRenderer(this, d);
            dr.size_changed.connect(()=>{this.render();});
            d.notify["name"].connect(()=>{
                dr.update_name_layout(this.node_view != null ? this.node_view.show_types : false);
            });
            d.notify["typename"].connect(()=>{
                dr.update_name_layout(this.node_view != null ? this.node_view.show_types : false);
            });
            this.dock_renderers.append(dr);
            dr.update_name_layout(this.node_view != null ? this.node_view.show_types : false);
            this.render();
        }

        public DockRenderer? get_dock_renderer(GFlow.Dock d) {
            foreach (DockRenderer dock_renderer in this.dock_renderers) {
                if (dock_renderer.get_dock() == d)
                    return dock_renderer;
            }
            return null;
        }

        private void unregister_dock(GFlow.Dock d) {
            DockRenderer? dr = this.get_dock_renderer(d);
            if (dr != null) {
                this.dock_renderers.remove(dr);
                //m.free();
            }
            this.render();
        }

        public Node.with_child(GFlow.Node n, Gtk.Widget c) {
            this(n);
            this.add(c);
            this.show_all();
            this.render();
        }

        public void set_node_allocation(Gtk.Allocation alloc) {
            int mw = (int)this.node_renderer.get_min_width(
                this.dock_renderers, this.get_children(),
                (int)this.get_border_width()
            );
            int mh = (int)this.node_renderer.get_min_height(
                this.dock_renderers, this.get_children(),
                (int)this.get_border_width()
            );

            if (alloc.width < mw)
                alloc.width = mw;
            if (alloc.height < mh)
                alloc.height = mh;
            this.node_allocation = alloc;
        }

        public void set_position(int x, int y) {
            this.node_allocation.x = x;
            this.node_allocation.y = y;
            this.node_view.queue_draw();
        }

        public unowned List<DockRenderer> get_dock_renderers() {
            return this.dock_renderers;
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
            this.render();
        }

        /**
         * Checks if the node needs to be resized in order to fill the minimum
         * size requirements
         */
        public void recalculate_size() {
            Gtk.Allocation alloc;
            this.get_node_allocation(out alloc);
            uint mw = this.node_renderer.get_min_width(
                this.dock_renderers, this.get_children(),
                (int) this.get_border_width()
            );
            uint mh = this.node_renderer.get_min_height(
                this.dock_renderers, this.get_children(),
                (int) this.get_border_width()
            );
            if (mw > alloc.width)
                alloc.width = (int)mw;
            if (mh > alloc.height)
                alloc.height = (int)mh;
            this.set_node_allocation(alloc);
        }
    }
}
