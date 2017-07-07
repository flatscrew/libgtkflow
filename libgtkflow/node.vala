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
    private class Node : Gtk.Container {
        // Determines the space between the title and the first dock (y-axis)
        // as well as the space between the title and the close-button if any (x-axis)

        public GFlow.Node gnode {public get; private set; default = null;}

        public NodeView? node_view {get; set; default=null;}

        private NodeRenderer? _node_renderer = null;
        public NodeRenderer? node_renderer {
            get {return this._node_renderer;}
            set {
                if (this._node_renderer != null) {
                    this._node_renderer.size_changed.disconnect(this.size_changed_callback);
                    this._node_renderer.child_redraw.disconnect(this.child_redraw_callback);
                }
                this._node_renderer = value;
                this._node_renderer.size_changed.connect(this.size_changed_callback);
                this._node_renderer.child_redraw.connect(this.child_redraw_callback);
            }
        }

        private void size_changed_callback() {
            this.render();
        }

        public Cairo.Context? current_cairo_ctx {get; set; default=null;}

        private void child_redraw_callback(Gtk.Widget w) {
            if (this.current_cairo_ctx == null) {
                warning("Child Redraw: No context to draw on");
                return;
            }
            Cairo.Context? cr = this.current_cairo_ctx;
            Gtk.Allocation node_alloc, child_alloc;
            this.get_allocation(out node_alloc);
            w.get_allocation(out child_alloc);
            cr.save();
            cr.translate(node_alloc.x + child_alloc.x, node_alloc.y + child_alloc.y);
            w.draw(cr);
            cr.restore();
        }

        private List<DockRenderer?> dock_renderers = new List<DockRenderer?>();

        private List<weak Gtk.Widget> childlist = new List<Gtk.Widget>();
        private HashTable<weak Gtk.Widget, ulong> childlist_alloc_handles = new HashTable<weak Gtk.Widget, ulong>(direct_hash, direct_equal);

        public Node (GFlow.Node n) {
            this.gnode = n;
            this.node_renderer = new DefaultNodeRenderer(this);
            foreach (GFlow.Dock d in this.gnode.get_sources())
                this.register_dock(d);
            foreach (GFlow.Dock d in this.gnode.get_sinks())
                this.register_dock(d);
            this.gnode.source_added.connect((s)=>{this.register_dock(s);});
            this.gnode.sink_added.connect((s)=>{this.register_dock(s);});
            this.gnode.source_removed.connect((s)=>{this.unregister_dock(s);});
            this.gnode.sink_removed.connect((s)=>{this.unregister_dock(s);});

            this.node_renderer.update_name_layout(this.gnode.name);
            this.gnode.notify["name"].connect(()=>{
                this.node_renderer.update_name_layout(this.gnode.name);
            });

            this.set_border_width(this.node_renderer.resize_handle_size);

            this.show_all();
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
            d.changed.connect(()=>{this.render();});
            this.dock_renderers.append(dr);
            dr.update_name_layout(this.node_view != null ? this.node_view.show_types : false);
            if (this.get_realized())
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
                this.dock_renderers.remove_link(
                    this.dock_renderers.find_custom(dr, (x,y)=>{return (int)(x!=y);})
                );
                //m.free();
            }
            if (this.get_realized())
                this.render();
        }

        public Node.with_child(GFlow.Node n, Gtk.Widget c) {
            this(n);
            this.add(c);
            this.show_all();
        }

        public void on_child_size_allocate(Gtk.Allocation _) {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            this.size_allocate(alloc);
            this.node_view.queue_draw();
        }

        public new void size_allocate(Gtk.Allocation alloc) {
            if (!this.get_visible() && !this.is_toplevel())
                return;
            int mw = (int)this.node_renderer.get_min_width(
                this.dock_renderers, this.childlist,
                (int)this.get_border_width()
            );
            int mh = (int)this.node_renderer.get_min_height(
                this.dock_renderers, this.childlist,
                (int)this.get_border_width()
            );

            if (alloc.width < mw)
                alloc.width = mw;
            if (alloc.height < mh)
                alloc.height = mh;
            (this as Gtk.Widget).size_allocate(alloc);
        }

        public void set_position(int x, int y) {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            alloc.x = x;
            alloc.y = y;
            this.size_allocate(alloc);
            this.node_view.queue_draw();
        }

        public unowned List<DockRenderer> get_dock_renderers() {
            return this.dock_renderers;
        }

        public override void forall_internal(bool include_internals, Gtk.Callback c) {
            foreach (Gtk.Widget child in this.childlist) {
                c(child);
            }
        }

        public override void add(Gtk.Widget w) {
            w.set_parent(this);
            this.childlist.append(w);
            ulong handle = w.size_allocate.connect(this.on_child_size_allocate);
            this.childlist_alloc_handles.set(w, handle);
            if (this.get_realized())
                this.render();
        }

        public override void remove(Gtk.Widget w) {
            w.unparent();
            ulong handle = this.childlist_alloc_handles.get(w);
            w.disconnect(handle);
            this.childlist_alloc_handles.remove(w);
            this.childlist.remove_link(
                this.childlist.find_custom(w, (x,y)=>{return (int)(x!=y);})
            );
        }

        public unowned List<weak Gtk.Widget> get_childlist() {
            return this.childlist;
        }

        public new void set_border_width(uint border_width) {
            int nr = this.node_renderer.resize_handle_size;
            if (border_width < nr) {
                warning("Cannot set border width smaller than %d", nr);
                return;
            }
            base.set_border_width(border_width);
            if (this.get_realized())
                this.render();
        }

        public override void realize() {
            this.recalculate_size();
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            var attr = Gdk.WindowAttr();
            attr.window_type = Gdk.WindowType.CHILD;
            attr.x = alloc.x;
            attr.y = alloc.y;
            attr.width = alloc.width;
            attr.height = alloc.height;
            attr.visual = this.get_visual();
            attr.event_mask = this.get_events();
            Gdk.WindowAttributesType mask = Gdk.WindowAttributesType.X 
                 | Gdk.WindowAttributesType.X 
                 | Gdk.WindowAttributesType.VISUAL;
            var window = new Gdk.Window(this.get_parent_window(), attr, mask);
            this.set_window(window);
            this.register_window(window);
            this.set_realized(true);
            this.render();
        }

        /**
         * Checks if the node needs to be resized in order to fill the minimum
         * size requirements
         */
        public void recalculate_size() {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            uint mw = this.node_renderer.get_min_width(
                this.dock_renderers, this.childlist,
                (int) this.get_border_width()
            );
            uint mh = this.node_renderer.get_min_height(
                this.dock_renderers, this.childlist,
                (int) this.get_border_width()
            );
            if (mw > alloc.width)
                alloc.width = (int)mw;
            if (mh > alloc.height)
                alloc.height = (int)mh;
            this.size_allocate(alloc);
        }
    }
}
