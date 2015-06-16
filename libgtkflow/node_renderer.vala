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

namespace GtkFlow {
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
        public abstract void update_name_layout();
    }

    private class DefaultNodeRenderer : NodeRenderer {
        private Pango.Layout layout;

        private weak Node node = null;

        public DefaultNodeRenderer(Node n) {
            this.node = n;
            this.node.gnode.render_request.connect(()=>{
                this.update_name_layout();
            });
        }

        public override void update_name_layout() {
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
                if (this.layout == null)
                    this.update_name_layout();
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
            DockRenderer dock_renderer;
            foreach (GFlow.Dock d in this.node.gnode.get_sinks()) {
                dock_renderer = this.node.get_dock_renderer_mapping(d).renderer;
                mw += dock_renderer.get_min_height();
            }
            foreach (GFlow.Dock d in this.node.gnode.get_sources()) {
                dock_renderer = this.node.get_dock_renderer_mapping(d).renderer;
                mw += dock_renderer.get_min_height();
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
                if (this.layout == null)
                    this.update_name_layout();
                this.layout.get_pixel_size(out width, out height);
                mw = width + title_spacing + delete_btn_size;
            }
            DockRenderer dock_renderer;
            foreach (GFlow.Dock d in this.node.gnode.get_sinks()) {
                dock_renderer = this.node.get_dock_renderer_mapping(d).renderer;
                t = dock_renderer.get_min_width();
                if (t > mw)
                    mw = t;
            }
            foreach (GFlow.Dock d in this.node.gnode.get_sources()) {
                dock_renderer = this.node.get_dock_renderer_mapping(d).renderer;
                t = dock_renderer.get_min_width();
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

            DockRenderer dock_renderer;
            foreach (GFlow.Dock s in this.node.gnode.get_sinks()) {
                dock_renderer = this.node.get_dock_renderer_mapping(s).renderer;
                if (s == d) {
                    p.x += (int)(node_allocation.x + this.node.border_width
                                 + dock_renderer.dockpoint_height/2);
                    p.y += (int)(node_allocation.y + this.node.border_width + title_offset
                              + dock_renderer.dockpoint_height/2 + i
                              * dock_renderer.get_min_height());
                    return p;
                }
                i++;
            }
            foreach (GFlow.Dock s in this.node.gnode.get_sources()) {
                dock_renderer = this.node.get_dock_renderer_mapping(s).renderer;
                if (s == d) {
                    p.x += (int)(node_allocation.x - this.node.border_width
                              + node_allocation.width - dock_renderer.dockpoint_height/2);
                    p.y += (int)(node_allocation.y + this.node.border_width + title_offset
                              + dock_renderer.dockpoint_height/2 + i
                              * dock_renderer.get_min_height());
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
            DockRenderer dock_renderer;
            foreach (GFlow.Dock s in this.node.gnode.get_sinks()) {
                dock_renderer = this.node.get_dock_renderer_mapping(s).renderer;
                mh = dock_renderer.get_min_height();
                dock_x = node_allocation.x + (int)this.node.border_width - (int)scroll_x;
                dock_y = node_allocation.y + (int)this.node.border_width + (int)title_offset
                         + i * mh - (int)scroll_y;
                if (x > dock_x && x < dock_x + dock_renderer.dockpoint_height
                        && y > dock_y && y < dock_y + dock_renderer.dockpoint_height )
                    return s;
                i++;
            }
            foreach (GFlow.Dock s in this.node.gnode.get_sources()) {
                dock_renderer = this.node.get_dock_renderer_mapping(s).renderer;
                mh = dock_renderer.get_min_height();
                dock_x = node_allocation.x + node_allocation.width
                         - (int)this.node.border_width - (int)scroll_x
                         - dock_renderer.dockpoint_height;
                dock_y = node_allocation.y + (int)this.node.border_width + (int)title_offset
                         + i * mh - (int)scroll_y;
                if (x > dock_x && x < dock_x + dock_renderer.dockpoint_height
                        && y > dock_y && y < dock_y + dock_renderer.dockpoint_height )
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

            DockRenderer dock_renderer;
            foreach (GFlow.Sink s in this.node.gnode.get_sinks()) {
                dock_renderer = this.node.get_dock_renderer_mapping(s).renderer;
                dock_renderer.draw_dock(cr, alloc.x + (int)this.node.border_width,
                                alloc.y+y_offset + (int) this.node.border_width, alloc.width);
                y_offset += dock_renderer.get_min_height();
            }
            foreach (GFlow.Source s in this.node.gnode.get_sources()) {
                dock_renderer = this.node.get_dock_renderer_mapping(s).renderer;
                dock_renderer.draw_dock(cr, alloc.x-(int)this.node.border_width,
                                  alloc.y+y_offset + (int) this.node.border_width, alloc.width);
                y_offset += dock_renderer.get_min_height();
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
}
