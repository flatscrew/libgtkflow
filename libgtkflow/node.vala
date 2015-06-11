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
    public interface DockRenderer {
        public abstract void draw_dock(Cairo.Context cr, 
                                         int offset_x, int offset_y, int width);
        public abstract int get_min_height();
        public abstract int get_min_width();
    }

    public abstract class NodeRenderer {
        public int title_spacing {get; set; default=15;}
        public int delete_btn_size {get; set; default=16;}
        public int resize_handle_size {get; set; default=10;}

        public abstract void draw_node (Cairo.Context cr);
        public abstract GFlow.Dock? get_dock_on_position(Gdk.Point p);
        public abstract Gdk.Point get_dock_position(GFlow.Dock d) throws GFlow.NodeError;
        public abstract bool is_on_closebutton(Gdk.Point p);
        public abstract bool is_on_resize_handle(Gdk.Point p);
        public abstract uint get_min_width();
        public abstract uint get_min_height();
    }

    private class DefaultDockRenderer : DockRenderer {
        public int dockpoint_height {get;set;default=16;}
        public int spacing_x {get; set; default=5;}
        public int spacing_y {get; set; default=3;}
        
        private Pango.Layout layout = null;
        private GFlow.Dock d = null;
        private Node node = null;

        public DefaultDockRenderer(Node n, GFlow.Dock d) {
            this.node = n;
            this.d = d;
            this.layout = this.node.create_pango_layout("");
            //FIXME: to listen to the signals we will need
            //       create a DockRenderer for each dock.
            //       would be nice to get signals for this
            //          i'd like to have sink_added, source_added,
            //       sink_removed, source_removed as signal on node
            //       as parameter they should supply the dock in question
            this.node.gnode.notify["name"].connect(()=>this.update_name_layout());
        }

        private void update_name_layout() {
            string labelstring;
            if (this.node != null && this.node.show_types) {
                labelstring = "<i>%s</i> : %s".printf(
                    this.d.typename ?? this.d.determine_typestring(),
                    this.d.name
                );
            } else {
                labelstring = this.d.name;
            }
            this.layout.set_markup(labelstring, -1);
            this.node.recalculate_size();
        }

        /**
         * Get the minimum width for this dock
         */
        public virtual int get_min_height() {
            int width, height;
            this.layout.get_pixel_size(out width, out height);
            return (int)(Math.fmax(height, dockpoint_height))+spacing_y;
        }

        /**
         * Get the minimum height for this dock
         */
        public virtual int get_min_width() {
            int width, height;
            this.layout.get_pixel_size(out width, out height);
            return (int)(width + dockpoint_height + spacing_y);
        }

        public void draw_dock(Cairo.Context cr,
                              int offset_x, int offset_y, int width) {
            if (d is GFlow.Sink)
                draw_sink(cr,offset_x,offset_y,width);
            if (d is GFlow.Source)
                draw_source(cr,offset_x,offset_y,width);
        }

        /**
         * Draw the given source onto a cairo context
         */
        public void draw_source(Cairo.Context cr,
                                int offset_x, int offset_y, int width) {
            Gtk.StyleContext sc = this.node.get_style_context();
            sc.save();
            if (this.d.is_connected())
                sc.set_state(Gtk.StateFlags.CHECKED);
            if (this.d.highlight)
                sc.set_state(sc.get_state() | Gtk.StateFlags.PRELIGHT);
            if (this.d.active)
                sc.set_state(sc.get_state() | Gtk.StateFlags.ACTIVE);
            sc.add_class(Gtk.STYLE_CLASS_RADIO);
            sc.render_option(cr, offset_x+width-dockpoint_height,offset_y,dockpoint_height,dockpoint_height);
            sc.restore();
            sc.save();
            sc.add_class(Gtk.STYLE_CLASS_BUTTON);
            Gdk.RGBA col = sc.get_color(Gtk.StateFlags.NORMAL);
            cr.set_source_rgba(col.red,col.green,col.blue,col.alpha);
            cr.move_to(offset_x + width - this.get_min_width(), offset_y);
            Pango.cairo_show_layout(cr, this.layout);
            sc.restore();
        }

        /**
         * Draw the given sink onto a cairo context
         */
        public void draw_sink(Cairo.Context cr, int offset_x, int offset_y, int width) {
            Gtk.StyleContext sc = this.node.get_style_context();
            sc.save();
            if (this.d.is_connected())
                sc.set_state(Gtk.StateFlags.CHECKED);
            if (this.d.highlight)
                sc.set_state(sc.get_state() | Gtk.StateFlags.PRELIGHT);
            if (this.d.active)
                sc.set_state(sc.get_state() | Gtk.StateFlags.ACTIVE);
            sc.add_class(Gtk.STYLE_CLASS_RADIO);
            sc.render_option(cr, offset_x,offset_y,dockpoint_height,dockpoint_height);
            sc.restore();
            sc.save();
            sc.add_class(Gtk.STYLE_CLASS_BUTTON);
            Gdk.RGBA col = sc.get_color(Gtk.StateFlags.NORMAL);
            cr.set_source_rgba(col.red,col.green,col.blue,col.alpha);
            cr.move_to(offset_x+dockpoint_height+spacing_x, offset_y);
            Pango.cairo_show_layout(cr, this.layout);
            sc.restore();
        }
    }

    private class DefaultNodeRenderer : NodeRenderer {
        private Pango.Layout layout;

        private weak Node node = null;

        public DefaultNodeRenderer(Node n) {
            this.node = n;
            this.node.gnode.notify["name"].connect(()=>this.update_name_layout());
        }

        public void update_name_layout() {
            this.layout = this.node.create_pango_layout("");
            this.layout.set_markup("<b>%s</b>".printf(this.node.gnode.name),-1);
            this.node.recalculate_size();
            this.node.node_view.queue_draw();
        }


        private uint get_title_line_height() {
            int width, height;
            if (this.node.gnode.name == "") {
                 width = height = 0;
            } else {
                this.layout.get_pixel_size(out width, out height);
            }
            return (uint)Math.fmax(height, delete_btn_size) + title_spacing;
        }

        /**
         * Returns the minimum height this node has to have
         */
        public override uint get_min_height() {
            uint mw = this.node.border_width*2;
            mw += this.get_title_line_height();
            foreach (GFlow.Dock d in this.node.gnode.get_sinks()) {
                mw += this.dock_renderer.get_min_height(d);
            }
            foreach (GFlow.Dock d in this.node.gnode.get_sources()) {
                mw += this.dock_renderer.get_min_height(d);
            }
            Gtk.Widget child = this.node.get_child();
            if (child != null) {
                int child_height, _;
                child.get_preferred_height(out child_height, out _);
                mw += child_height;
            }
            return mw;
        }

        /**
         * Returns the minimum width this node has to have
         */
        public override uint get_min_width() {
            uint mw = 0;
            int t = 0;
            if (this.node.name != "") {
                int width, height;
                this.layout.get_pixel_size(out width, out height);
                mw = width + title_spacing + delete_btn_size;
            }
            foreach (GFlow.Dock d in this.node.gnode.get_sinks()) {
                t = d.get_min_width();
                if (t > mw)
                    mw = t;
            }
            foreach (GFlow.Dock d in this.node.gnode.get_sources()) {
                t = d.get_min_width();
                if (t > mw)
                    mw = t;
            }
            Gtk.Widget child = this.node.get_child();
            if (child != null) {
                int child_width, _;
                child.get_preferred_width(out child_width, out _);
                if (child_width > mw)
                    mw = child_width;
            }
            return mw + this.node.border_width*2;
        }

        /**
         * Returns true if the point is on the close-button of the node
         */
        public override bool is_on_closebutton(Gdk.Point p) {
            int x = p.x;
            int y = p.y;

            double scroll_x = this.node.node_view != null ? this.node.node_view.hadjustment.value : 0;
            double scroll_y = this.node.node_view != null ? this.node.node_view.vadjustment.value : 0;

            Gtk.Allocation alloc;
            this.node.get_node_allocation(out alloc);
            int x_left = alloc.x + alloc.width - delete_btn_size
                                 - (int)this.node.border_width - (int)scroll_x;
            int x_right = x_left + delete_btn_size;
            int y_top = alloc.y + (int)this.node.border_width - (int)scroll_y;
            int y_bot = y_top + delete_btn_size;
            return x > x_left && x < x_right && y > y_top && y < y_bot;
        }

        /**
         * Returns true if the point is in the resize-drag area
         */
        public override bool is_on_resize_handle(Gdk.Point p) {
            int x = p.x;
            int y = p.y;

            double scroll_x = this.node.node_view != null ? this.node.node_view.hadjustment.value : 0;
            double scroll_y = this.node.node_view != null ? this.node.node_view.vadjustment.value : 0;

            Gtk.Allocation alloc;
            this.node.get_node_allocation(out alloc);
            int x_right = alloc.x + alloc.width - (int)scroll_x;
            int x_left = x_right - resize_handle_size;
            int y_bot = alloc.y + alloc.height - (int)scroll_y;
            int y_top = y_bot - resize_handle_size;
            return x > x_left && x < x_right && y > y_top && y < y_bot;
        }

        /**
         * Returns the position of the given dock.
         * This is obviously bullshit. GFlow.Docks should be able to know
         * their own position
         */
        public override Gdk.Point get_dock_position(GFlow.Dock d) throws GFlow.NodeError {
            int i = 0;
            Gdk.Point p = {0,0};

            if (this.node.node_view != null) {
                p.x -= (int)this.node.node_view.hadjustment.get_value();
                p.y -= (int)this.node.node_view.vadjustment.get_value();
            }

            uint title_offset = this.get_title_line_height();
            Gtk.Allocation node_allocation;
            this.node.get_node_allocation(out node_allocation);

            foreach (GFlow.Dock s in this.node.gnode.get_sinks()) {
                if (s == d) {
                    p.x += (int)(node_allocation.x + this.node.border_width + dockpoint_height/2);
                    p.y += (int)(node_allocation.y + this.node.border_width + title_offset
                              + dockpoint_height/2 + i * s.get_min_height());
                    return p;
                }
                i++;
            }
            foreach (GFlow.Dock s in this.node.gnode.get_sources()) {
                if (s == d) {
                    p.x += (int)(node_allocation.x - this.node.border_width
                              + node_allocation.width - dockpoint_height/2);
                    p.y += (int)(node_allocation.y + this.node.border_width + title_offset
                              + dockpoint_height/2 + i * s.get_min_height());
                    return p;
                }
                i++;
            }
            throw new GFlow.NodeError.NO_SUCH_DOCK("There is no such dock in this.node node");
        }

        /**
         * Determines whether the mousepointer is hovering over a dock on this node
         */
        public override GFlow.Dock? get_dock_on_position(Gdk.Point p) {
            int x = p.x;
            int y = p.y;

            double scroll_x = this.node.node_view != null ? this.node.node_view.hadjustment.value : 0;
            double scroll_y = this.node.node_view != null ? this.node.node_view.vadjustment.value : 0;

            int i = 0;

            Gtk.Allocation node_allocation;
            this.node.get_node_allocation(out node_allocation);
            int dock_x, dock_y, mh;
            uint title_offset;
            title_offset = this.get_title_line_height();
            foreach (GFlow.Dock s in this.node.gnode.get_sinks()) {
                mh = this.node.dock_renderer.get_min_height(s);
                dock_x = node_allocation.x + (int)this.node.border_width - (int)scroll_x;
                dock_y = node_allocation.y + (int)this.node.border_width + (int)title_offset
                         + i * mh - (int)scroll_y;
                if (x > dock_x && x < dock_x + dockpoint_height
                        && y > dock_y && y < dock_y + dockpoint_height )
                    return s;
                i++;
            }
            foreach (GFlow.Dock s in this.node.gnode.get_sources()) {
                mh = this.node.dock_renderer.get_min_height(s);
                dock_x = node_allocation.x + node_allocation.width
                         - (int)this.node.border_width - dockpoint_height - (int)scroll_x;
                dock_y = node_allocation.y + (int)this.node.border_width + (int)title_offset
                         + i * mh - (int)scroll_y;
                if (x > dock_x && x < dock_x + dockpoint_height
                        && y > dock_y && y < dock_y + dockpoint_height )
                    return s;
                i++;
            }
            return null;
        }

        /**
         * Draw this node on the given cairo context
         */
        public override void draw_node(Cairo.Context cr) {
            Gtk.Allocation alloc;
            this.node.get_node_allocation(out alloc);

            if (this.node.node_view != null) {
                alloc.x -= (int)this.node.node_view.hadjustment.get_value();
                alloc.y -= (int)this.node.node_view.vadjustment.get_value();
            }

            Gtk.StyleContext sc = this.node.get_style_context();
            sc.save();
            sc.add_class(Gtk.STYLE_CLASS_BUTTON);
            sc.render_background(cr, alloc.x, alloc.y, alloc.width, alloc.height);
            sc.render_frame(cr, alloc.x, alloc.y, alloc.width, alloc.height);
            sc.restore();

            int y_offset = 0;

            if (this.node.gnode.name != "") {
                sc.save();
                cr.save();
                sc.add_class(Gtk.STYLE_CLASS_BUTTON);
                Gdk.RGBA col = sc.get_color(Gtk.StateFlags.NORMAL);
                cr.set_source_rgba(col.red,col.green,col.blue,col.alpha);
                cr.move_to(alloc.x + this.node.border_width,
                           alloc.y + (int) this.node.border_width + y_offset);
                Pango.cairo_show_layout(cr, this.layout);
                cr.restore();
                sc.restore();
            }
            if (this.node.node_view != null && this.node.node_view.editable) {
                Gtk.IconTheme it = Gtk.IconTheme.get_default();
                try {
                    cr.save();
                    Gdk.Pixbuf icon_pix = it.load_icon("edit-delete", delete_btn_size, 0);
                    Gdk.cairo_set_source_pixbuf(
                        cr, icon_pix,
                        alloc.x+alloc.width-delete_btn_size-this.node.border_width,
                        alloc.y+this.node.border_width
                    );
                    cr.paint();
                } catch (GLib.Error e) {
                    warning("Could not load close-node-icon 'edit-delete'");
                } finally {
                    cr.restore();
                }
            }
            y_offset += (int)this.get_title_line_height();

            foreach (GFlow.Sink s in this.node.gnode.get_sinks()) {
                this.node.dock_renderer.draw_dock(cr, alloc.x + (int)this.node.border_width,
                                alloc.y+y_offset + (int) this.node.border_width);
                y_offset += this.node.dock_renderer.get_min_height(s);
            }
            foreach (GFlow.Source s in this.node.gnode.get_sources()) {
                this.node.dock_renderer.draw_dock(cr, alloc.x-(int)this.node.border_width,
                                  alloc.y+y_offset + (int) this.node.border_width, alloc.width);
                y_offset += this.node.dock_renderer.get_min_height(s);
            }

            Gtk.Widget child = this.node.get_child();
            if (child != null) {
                Gtk.Allocation child_alloc = {0,0,0,0};
                child_alloc.x = alloc.x + (int)this.node.border_width;
                child_alloc.y = alloc.y + (int)this.node.border_width + y_offset;
                child_alloc.width = alloc.width - 2 * (int)this.node.border_width;
                child_alloc.height = alloc.height - 2 * (int)this.node.border_width - y_offset;
                child.size_allocate(child_alloc);

                this.node.propagate_draw(child, cr);
            }
            // Draw resize handle
            sc.save();
            cr.save();
            cr.set_source_rgba(0.5,0.5,0.5,0.5);
            cr.move_to(alloc.x + alloc.width,
                       alloc.y + alloc.height);
            cr.line_to(alloc.x + alloc.width - resize_handle_size,
                       alloc.y + alloc.height);
            cr.line_to(alloc.x + alloc.width,
                       alloc.y + alloc.height - resize_handle_size);
            cr.fill();
            cr.stroke();
            cr.restore();
            sc.restore();
        }
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
        public DockRenderer? dock_renderer {get; set; default=null;}

        private Gtk.Allocation node_allocation;

        public bool show_types {get; set; default=false;}

        public Node (GFlow.Node n) {
            this.gnode = n;
            this.node_allocation = {0,0,0,0};
            this.node_renderer = new DefaultNodeRenderer(this);
            this.set_border_width(this.node_renderer.resize_handle_size);
            this.recalculate_size();
        }

        public Node.with_child(GFlow.Node n, Gtk.Widget c) {
            this(n);
            this.add(c);
        }

        public void set_node_renderer(NodeRenderer r) {
            this.node_renderer = r;
        }

        public void set_dock_renderer(DockRenderer r) {
            this.dock_renderer = r;
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
            base.add(w);
        }

        public override void remove(Gtk.Widget w) {
            w.unparent();
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

        public void set_node_view(NodeView? n) {
            this.node_view = n;
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

        /**
         * Causes this node's NodeRenderer to draw
         * the node
         */
        public void draw_node(Cairo.Context cr) {
            this.node_renderer.draw_node(cr);
        }

    }
}
