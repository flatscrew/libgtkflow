/********************************************************************
# Copyright 2014-2020 Daniel 'grindhold' Brendle
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
    /**
     * A Widget that draws a minmap of a {@link GtkFlow.NodeView}
     *
     * Please set the nodeview property after integrating the referenced
     * {@link GtkFlow.NodeView} into its respective container
     */
    public class Minimap : Gtk.DrawingArea {
        private GtkFlow.NodeView? _nodeview = null;
        private Gtk.ScrolledWindow? _scrolledwindow = null;
        private ulong draw_signal = 0;
        private ulong hadjustment_signal = 0;
        private ulong vadjustment_signal = 0;

        private int offset_x = 0;
        private int offset_y = 0;
        private double ratio = 0.0;
        private int rubber_width = 0;
        private int rubber_height = 0;
        private bool move_rubber = false;
        /**
         * The nodeview that this Minimap should depict
         *
         * You may either add a {@link GtkFlow.NodeView} directly or a
         * {@link Gtk.ScrolledWindow} that contains a {@link GtkFlow.NodeView}
         * as its child.
         */
        public NodeView nodeview {
            get {
                return this._nodeview;
            }
            set {
                if (this._nodeview != null) {
                    GLib.SignalHandler.disconnect(this._nodeview, this.draw_signal);
                }
                if (this._scrolledwindow != null) {
                    GLib.SignalHandler.disconnect(this._nodeview, this.hadjustment_signal);
                    GLib.SignalHandler.disconnect(this._nodeview, this.vadjustment_signal);
                }
                if (value == null) {
                    this._nodeview = null;
                    this._scrolledwindow = null;
                } else {
                    this._nodeview = value;
                    this._scrolledwindow = null;
                    if (value.get_parent() is Gtk.ScrolledWindow) {
                        this._scrolledwindow = value.get_parent() as Gtk.ScrolledWindow;
                    } else {
                        if (value.get_parent() is Gtk.Viewport) {
                            if (value.get_parent().get_parent() is Gtk.ScrolledWindow) {
                                this._scrolledwindow = value.get_parent().get_parent() as Gtk.ScrolledWindow;
                                this.hadjustment_signal = this._scrolledwindow.hadjustment.notify["value"].connect(
                                    ()=>{this.queue_draw();}
                                );
                                this.vadjustment_signal = this._scrolledwindow.vadjustment.notify["value"].connect(
                                    ()=>{this.queue_draw();}
                                );
                            }
                        }
                    }
                    this.draw_signal = this._nodeview.draw_minimap.connect(()=>{this.queue_draw(); });
                }
                this.queue_draw();
            }
        }

        private Gtk.EventControllerMotion ctr_motion;
        private Gtk.GestureClick ctr_click;

        /**
         * Create a new Minimap
         */
        public Minimap() {
            this.set_size_request(50,50);

            this.ctr_motion = new Gtk.EventControllerMotion();
            this.add_controller(this.ctr_motion);
            this.ctr_click = new Gtk.GestureClick();
            this.add_controller(this.ctr_click);


            this.ctr_click.pressed.connect((n,x,y)=> {this.do_button_press_event(x,y);});
            this.ctr_click.end.connect(()=>{this.do_button_release_event(); });
            this.ctr_motion.motion.connect((x,y)=>{this.do_motion_notify_event(x,y); });
        }

        private void do_button_press_event(double x, double y) {
            this.move_rubber = true;
            double halloc = double.max(0, x - offset_x - rubber_width / 2) * ratio;
            double valloc = double.max(0, y - offset_y - rubber_height / 2) * ratio;
            this._scrolledwindow.hadjustment.value = halloc;
            this._scrolledwindow.vadjustment.value = valloc;
        }

        private void do_motion_notify_event(double x, double y) {
            if (!this.move_rubber || this._scrolledwindow == null) {
                return;
            }
            double halloc = double.max(0, x - offset_x - rubber_width / 2) * ratio;
            double valloc = double.max(0, y - offset_y - rubber_height / 2) * ratio;
            this._scrolledwindow.hadjustment.value = halloc;
            this._scrolledwindow.vadjustment.value = valloc;
        }

        private void do_button_release_event() {
            this.move_rubber = false;
        }

        /**
         * Draws the minimap. This method is called internally
         */
        public override void snapshot(Gtk.Snapshot sn) {
            Graphene.Rect rect;
            //var rect = Graphene.Rect().init(0,0,this.get_width(), this.get_height());
            //var cr = sn.append_cairo(rect);
            Gtk.StyleContext sc = this.get_style_context();
            Gtk.Allocation own_alloc;
            this.get_allocation(out own_alloc);
            //sc.render_background(cr, 0, 0, own_alloc.width, own_alloc.height);

            if (this._nodeview != null) {
                Gtk.Allocation nv_alloc;
                this._nodeview.get_allocation(out nv_alloc);
                this.offset_x = 0;
                this.offset_y = 0;
                int height = 0;
                int width = 0;
                if (own_alloc.width> own_alloc.height) {
                    width = (int)((double) nv_alloc.width / nv_alloc.height * own_alloc.height);
                    height = own_alloc.height;
                    offset_x = (own_alloc.width - width ) / 2;
                } else {
                    height = (int)((double) nv_alloc.height / nv_alloc.width * own_alloc.width);
                    width = own_alloc.width;
                    offset_y = (own_alloc.height - height ) / 2;
                }
                this.ratio = (double) nv_alloc.width / width;
                var child = this.nodeview.get_first_child();
                while (child != null) {
                    var n = (Node)child;
                    Gtk.Allocation alloc;
                    n.get_allocation(out alloc);
                    Gdk.RGBA color;
                    if (n.highlight_color != null) {
                        color = n.highlight_color;
                    } else {
                        color = {0.4f,0.4f,0.4f,0.5f};
                    }
                    rect = Graphene.Rect().init(
                        (int)(offset_x + alloc.x/ratio),
                        (int)(offset_y + alloc.y/ratio),
                        (int)(alloc.width/ratio),
                        (int)(alloc.height/ratio)
                    );
                    sn.append_color(color, rect);
                    child = child.get_next_sibling();
                }
                if (this._scrolledwindow != null) {
                    Gtk.Allocation sw_alloc;
                    this._scrolledwindow.get_allocation(out sw_alloc);
                    if (sw_alloc.width < nv_alloc.width || sw_alloc.height < nv_alloc.height) {
                        rect = Graphene.Rect().init(
                            (int)(offset_x + this._scrolledwindow.hadjustment.value / ratio),
                            (int)(offset_y + this._scrolledwindow.vadjustment.value / ratio),
                            (int)(sw_alloc.width / ratio),
                            (int)(sw_alloc.height / ratio)
                        );
                        sn.append_color({0.0f,0.2f,0.6f,0.5f}, rect);
                    }
                }
            }
        }
    }
}
