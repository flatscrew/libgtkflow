/********************************************************************
# Copyright 2014-2019 Daniel 'grindhold' Brendle
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
    public class DocklineNodeRenderer : NodeRenderer {
        private Pango.Layout layout;

        internal DocklineNodeRenderer(Node n) {
            this.layout = (new Gtk.Label("")).create_pango_layout("");
        }

        public override void update_name_layout(string name) {
            this.layout.set_markup("<b>%s</b>".printf(name),-1);
            this.size_changed();
        }


        private uint get_title_line_height() {
            // FIXME: this is a bad solution. it should not happen in the first place
            //        probably related to the remaining Pango-CRITICALs. but it works.
            if (this.layout == null)
                return 25;
            int width, height;
            this.layout.get_pixel_size(out width, out height);
            return (uint)Math.fmax(height, delete_btn_size) + title_spacing;
        }

        /**
         * Returns the minimum height this node has to have
         */
        public override uint get_min_height(List<DockRenderer> dock_renderers,
                                            List<Gtk.Widget> children,
                                            int border_width) {
            uint mh = border_width*2;
            mh += this.get_title_line_height();
            uint source_height = 0;
            uint sink_height = 0;
            foreach (DockRenderer dock_renderer in dock_renderers) {
                if (dock_renderer.get_dock() is GFlow.Source)
                    source_height += dock_renderer.get_min_height();
                if (dock_renderer.get_dock() is GFlow.Sink)
                    sink_height += dock_renderer.get_min_height();
            }
            mh += uint.max(sink_height, source_height);
            Gtk.Widget child = children.nth_data(0);
            if (child != null) {
                int child_height, _;
                child.get_preferred_height(out child_height, out _);
                mh += child_height;
            }
            return mh;
        }

        /**
         * Returns the minimum width this node has to have
         */
        public override uint get_min_width(List<DockRenderer> dock_renderers,
                                           List<Gtk.Widget> children,
                                           int border_width) {
            uint mw = 0;
            int t = 0;
            if (this.layout.get_text() != "") {
                int width, height;
                this.layout.get_pixel_size(out width, out height);
                mw = width + title_spacing + delete_btn_size;
            }
            uint mw_sources = 0;
            uint mw_sinks = 0;
            foreach (DockRenderer dr in dock_renderers) {
                t = dr.get_min_width();
                if (dr.get_dock() is GFlow.Sink)
                    mw_sinks = uint.max(t, mw_sinks);
                if (dr.get_dock() is GFlow.Source)
                    mw_sources = uint.max(t, mw_sources);
            }
            mw = mw_sinks + mw_sources;
            Gtk.Widget child = children.nth_data(0);
            if (child != null) {
                int child_width, _;
                child.get_preferred_width(out child_width, out _);
                if (child_width > mw)
                    mw = child_width;
            }
            return mw + border_width*2;
        }

        /**
         * Returns true if the point is on the close-button of the node
         */
        public override bool is_on_closebutton(Gdk.Point p,
                                               Gtk.Allocation alloc,
                                               uint border_width) {
            int x = p.x;
            int y = p.y;

            int x_left, x_right, y_top, y_bot;

            if ((this.get_style().get_state() & Gtk.StateFlags.DIR_LTR) > 0 ){
                x_left = alloc.x + alloc.width - delete_btn_size
                                     - (int)border_width;
                x_right = x_left + delete_btn_size;
                y_top = alloc.y + (int)border_width;
                y_bot = y_top + delete_btn_size;
            } else {
                x_left = alloc.x + (int)border_width;
                x_right = x_left + delete_btn_size;
                y_top = alloc.y + (int)border_width;
                y_bot = y_top + delete_btn_size;
            }
            return x > x_left && x < x_right && y > y_top && y < y_bot;
        }

        /**
         * Returns true if the point is in the resize-drag area
         */
        public override bool is_on_resize_handle(Gdk.Point p,
                                                 Gtk.Allocation alloc,
                                                 uint border_width) {
            int x = p.x;
            int y = p.y;

            int x_right, x_left, y_bot, y_top;

            if ((this.get_style().get_state() & Gtk.StateFlags.DIR_LTR) > 0 ){
                x_right = alloc.x + alloc.width;
                x_left = x_right - resize_handle_size;
                y_bot = alloc.y + alloc.height;
                y_top = y_bot - resize_handle_size;
            } else {
                x_left = alloc.x;
                x_right = x_left + resize_handle_size;
                y_bot = alloc.y + alloc.height;
                y_top = y_bot - resize_handle_size;
            }
            return x > x_left && x < x_right && y > y_top && y < y_bot;
        }

        /**
         * Returns the position of the given dock.
         * This is obviously bullshit. GFlow.Docks should be able to know
         * their own position
         */
        public override bool get_dock_position(GFlow.Dock d,
                                                    List<DockRenderer> dock_renderers,
                                                    int border_width,
                                                    Gtk.Allocation alloc,
                                                    out int x,
                                                    out int y) {
            int i = 0;
            x = y = 0;

            uint title_offset = this.get_title_line_height();

            foreach(DockRenderer dock_renderer in dock_renderers) {
                GFlow.Dock s = dock_renderer.get_dock();
                if (s == d) {
                    if ((this.get_style().get_state() & Gtk.StateFlags.DIR_LTR) > 0 ){
                        if (s is GFlow.Sink) {
                            x += alloc.x + border_width
                                         + dock_renderer.dockpoint_height/2;
                            y += alloc.y + border_width + (int)title_offset
                                      + dock_renderer.dockpoint_height/2 + i
                                      * dock_renderer.get_min_height();
                            return true;
                        } else if (s is GFlow.Source) {
                            x += alloc.x - border_width
                                      + alloc.width - dock_renderer.dockpoint_height/2;
                            y += alloc.y + border_width + (int)title_offset
                                      + dock_renderer.dockpoint_height/2 + i
                                      * dock_renderer.get_min_height();
                            return true;
                        }
                    } else {
                        if (s is GFlow.Sink) {
                            x += alloc.x - border_width
                                      + alloc.width - dock_renderer.dockpoint_height/2;
                            y += alloc.y + border_width + (int)title_offset
                                      + dock_renderer.dockpoint_height/2 + i
                                      * dock_renderer.get_min_height();
                            return true;
                        } else if (s is GFlow.Source) {
                            x += alloc.x + border_width
                                         + dock_renderer.dockpoint_height/2;
                            y += alloc.y + border_width + (int)title_offset
                                      + dock_renderer.dockpoint_height/2 + i
                                      * dock_renderer.get_min_height();
                            return true;
                        }
                    }
                }
                if (s.get_type() == d.get_type()) {
                    i++;
                }
            }
            return false;
        }

        /**
         * Determines whether the mousepointer is hovering over a dock on this node
         */
        public override GFlow.Dock? get_dock_on_position(Gdk.Point p,
                                                    List<DockRenderer> dock_renderers,
                                                    uint border_width,
                                                    Gtk.Allocation alloc ) {
            int x = p.x;
            int y = p.y;

            int source_count = 0;
            int sink_count = 0;

            int dock_x, dock_y, mh;
            uint title_offset;
            title_offset = this.get_title_line_height();

            foreach (DockRenderer dock_renderer in dock_renderers) {
                GFlow.Dock s = dock_renderer.get_dock();
                mh = dock_renderer.get_min_height();
                if ((this.get_style().get_state() & Gtk.StateFlags.DIR_LTR) > 0 ){
                    if (s is GFlow.Sink) {
                        dock_x = alloc.x + (int)border_width;
                        dock_y = alloc.y + (int)border_width + (int)title_offset
                                 + sink_count * mh;
                        if (x > dock_x && x < dock_x + dock_renderer.dockpoint_height
                                && y > dock_y && y < dock_y + dock_renderer.dockpoint_height )
                            return s;
                        sink_count++;
                    } else if (s is GFlow.Source) {
                        dock_x = alloc.x + alloc.width
                                 - (int)border_width
                                 - dock_renderer.dockpoint_height;
                        dock_y = alloc.y + (int)border_width + (int)title_offset
                                 + source_count * mh;
                        if (x > dock_x && x < dock_x + dock_renderer.dockpoint_height
                                && y > dock_y && y < dock_y + dock_renderer.dockpoint_height )
                            return s;
                        source_count++;
                    }
                } else {
                    if (s is GFlow.Sink) {
                        dock_x = alloc.x + alloc.width
                                 - (int)border_width
                                 - dock_renderer.dockpoint_height;
                        dock_y = alloc.y + (int)border_width + (int)title_offset
                                 + sink_count * mh;
                        if (x > dock_x && x < dock_x + dock_renderer.dockpoint_height
                                && y > dock_y && y < dock_y + dock_renderer.dockpoint_height )
                            return s;
                        sink_count++;
                    } else if (s is GFlow.Source) {
                        dock_x = alloc.x + (int)border_width;
                        dock_y = alloc.y + (int)border_width + (int)title_offset
                                 + source_count * mh;
                        if (x > dock_x && x < dock_x + dock_renderer.dockpoint_height
                                && y > dock_y && y < dock_y + dock_renderer.dockpoint_height )
                            return s;
                        source_count++;
                    }
                }
            }
            return null;
        }

        /**
         * Returns a Gtk.StyleContext matching a given selector
         */
        private Gtk.StyleContext get_style() {
            var b = new Gtk.Button();
            return b.get_style_context();
        }

        /**
         * Draw this node on the given cairo context
         */
        public override void draw_node(Gtk.Widget w, Cairo.Context cr,
                                       Gtk.Allocation alloc,
                                       List<DockRenderer> dock_renderers,
                                       List<Gtk.Widget> children,
                                       int border_width,
                                       NodeProperties node_properties) {
            bool editable = node_properties.editable;
            bool deletable = node_properties.deletable;
            bool resizable = node_properties.resizable;
            bool selected = node_properties.selected;
            var sc = this.get_style();
            sc.save();
            sc.render_background(cr, alloc.x, alloc.y, alloc.width, alloc.height);
            sc.render_frame(cr, alloc.x, alloc.y, alloc.width, alloc.height);
            sc.restore();

            int y_offset = 0;

            if (this.layout.get_text() != "") {
                sc.save();
                cr.save();
                sc.add_class(Gtk.STYLE_CLASS_BUTTON);
                Gdk.RGBA col = sc.get_color(Gtk.StateFlags.NORMAL);
                cr.set_source_rgba(col.red,col.green,col.blue,col.alpha);
                if ((this.get_style().get_state() & Gtk.StateFlags.DIR_LTR) > 0 ){
                    cr.move_to(alloc.x + border_width,
                               alloc.y + (int) border_width + y_offset);
                } else {
                    cr.move_to(alloc.x + 2*border_width + delete_btn_size,
                               alloc.y + (int) border_width + y_offset);
                }
                Pango.cairo_show_layout(cr, this.layout);
                cr.restore();
                sc.restore();
            }
            if (editable && deletable) {
                Gtk.IconTheme it = Gtk.IconTheme.get_default();
                try {
                    cr.save();
                    Gdk.Pixbuf icon_pix = it.load_icon("edit-delete", delete_btn_size, 0);
                    if ((this.get_style().get_state() & Gtk.StateFlags.DIR_LTR) > 0 ){
                        Gdk.cairo_set_source_pixbuf(
                            cr, icon_pix,
                            alloc.x+alloc.width-delete_btn_size-border_width,
                            alloc.y+border_width
                        );
                    } else {
                        Gdk.cairo_set_source_pixbuf(
                            cr, icon_pix,
                            alloc.x+border_width,
                            alloc.y+border_width
                        );
                    }
                    cr.paint();
                } catch (GLib.Error e) {
                    warning("Could not load close-node-icon 'edit-delete'");
                } finally {
                    cr.restore();
                }
            }
            y_offset += (int)this.get_title_line_height();
            int y_offset_sources = y_offset;

            int x_offset_sources = 0;
            foreach (DockRenderer dock_renderer in dock_renderers) {
                if (dock_renderer.get_dock() is GFlow.Sink) {
                    x_offset_sources = int.max(x_offset_sources, dock_renderer.get_min_width());
                }
            }

            foreach (DockRenderer dock_renderer in dock_renderers) {
                if (dock_renderer.get_dock() is GFlow.Sink) {
                    dock_renderer.draw_dock(w, cr, sc, alloc.x + (int)border_width,
                                alloc.y+y_offset + (int) border_width, alloc.width);
                    y_offset += dock_renderer.get_min_height();
                } else if (dock_renderer.get_dock() is GFlow.Source) {
                    dock_renderer.draw_dock(w, cr, sc, alloc.x-(int)border_width,
                                  alloc.y+y_offset_sources + (int) border_width, alloc.width);
                    y_offset_sources += dock_renderer.get_min_height();
                }
            }

            y_offset = int.max(y_offset, y_offset_sources);

            Gtk.Widget child = children.nth_data(0);
            if (child != null) {
                Gtk.Allocation child_alloc = {0,0,0,0};
                child_alloc.x = (int)border_width;
                child_alloc.y = (int)border_width + y_offset;
                child_alloc.width = alloc.width - 2 * (int)border_width;
                child_alloc.height = alloc.height - 2 * (int)border_width - y_offset;
                child.size_allocate(child_alloc);
                this.child_redraw(child);

            }
            // Draw resize handle
            if (resizable) {
                sc.save();
                cr.save();
                cr.set_source_rgba(0.5,0.5,0.5,0.5);
                if ((this.get_style().get_state() & Gtk.StateFlags.DIR_LTR) > 0 ){
                    cr.move_to(alloc.x + alloc.width,
                               alloc.y + alloc.height);
                    cr.line_to(alloc.x + alloc.width - resize_handle_size,
                               alloc.y + alloc.height);
                    cr.line_to(alloc.x + alloc.width,
                               alloc.y + alloc.height - resize_handle_size);
                } else {
                    cr.move_to(alloc.x,
                               alloc.y + alloc.height);
                    cr.line_to(alloc.x + resize_handle_size,
                               alloc.y + alloc.height);
                    cr.line_to(alloc.x,
                               alloc.y + alloc.height - resize_handle_size);
                }
                cr.fill();
                cr.stroke();
                cr.restore();
                sc.restore();
            }

            if (selected) {
                draw_rubberband(w, cr, alloc.x, alloc.y, Gtk.StateFlags.NORMAL, &alloc.width, &alloc.height);
            }
        }
    }
}
