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
                    this.draw_signal = this._nodeview.draw.connect((w, cr)=>{this.queue_draw(); return true;});
                }
                this.queue_draw();
            }
        }

        /**
         * Create a new Minimap
         */
        public Minimap() {
            this.set_size_request(50,50);
            this.button_press_event.connect((e)=> {return this.do_button_press_event(e);});
            this.button_release_event.connect((e)=>{ return this.do_button_release_event(e); });
            this.motion_notify_event.connect((e)=>{ return this.do_motion_notify_event(e); });
        }

        private bool do_button_press_event(Gdk.EventButton e) {
            if (   e.type == Gdk.EventType.@2BUTTON_PRESS
                || e.type == Gdk.EventType.@3BUTTON_PRESS)
                return false;
            this.move_rubber = true;
            double halloc = double.max(0, e.x - offset_x - rubber_width / 2) * ratio;
            double valloc = double.max(0, e.y - offset_y - rubber_height / 2) * ratio;
            this._scrolledwindow.hadjustment.value = halloc;
            this._scrolledwindow.vadjustment.value = valloc;
            return true;
        }

        private bool do_motion_notify_event(Gdk.EventMotion e) {
            if (!this.move_rubber || this._scrolledwindow == null) {
                return false;
            }
            double halloc = double.max(0, e.x - offset_x - rubber_width / 2) * ratio;
            double valloc = double.max(0, e.y - offset_y - rubber_height / 2) * ratio;
            this._scrolledwindow.hadjustment.value = halloc;
            this._scrolledwindow.vadjustment.value = valloc;
            return true;
        }

        private bool do_button_release_event(Gdk.EventButton e) {
            if (   e.type == Gdk.EventType.@2BUTTON_PRESS
                || e.type == Gdk.EventType.@3BUTTON_PRESS)
                return false;
            this.move_rubber = false;
            return true;
        }

        /**
         * Draws the minimap. This method is called internally
         */
        public override bool draw(Cairo.Context cr) {
            Gtk.StyleContext sc = this.get_style_context();
            Gtk.Allocation own_alloc;
            this.get_allocation(out own_alloc);
            sc.render_background(cr, 0, 0, own_alloc.width, own_alloc.height);

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
                foreach(Node n in this._nodeview.get_nodes()) {
                    Gtk.Allocation alloc;
                    n.get_allocation(out alloc);
                    cr.save();
                    if (n.highlight_color != null) {
                        cr.set_source_rgba(n.highlight_color.red,n.highlight_color.green,n.highlight_color.blue,0.5);
                    } else {
                        cr.set_source_rgba(0.4,0.4,0.4,0.5);
                    }
                    cr.rectangle(offset_x + alloc.x/ratio, offset_y + alloc.y/ratio, alloc.width/ratio, alloc.height/ratio);
                    cr.fill();
                    cr.restore();
                }
                if (this._scrolledwindow != null) {
                    Gtk.Allocation sw_alloc;
                    this._scrolledwindow.get_allocation(out sw_alloc);
                    if (sw_alloc.width < nv_alloc.width || sw_alloc.height < nv_alloc.height) {
                        this.rubber_width = (int)(sw_alloc.width / ratio);
                        this.rubber_height = (int)(sw_alloc.height / ratio);
                        draw_rubberband(this, cr,
                                        (int)(offset_x + this._scrolledwindow.hadjustment.value / ratio), 
                                        (int)(offset_y + this._scrolledwindow.vadjustment.value / ratio),
                                        Gtk.StateFlags.NORMAL,
                                        &this.rubber_width, &this.rubber_height);
                    }
                }
            }
            return true;
        }

        /**
         * Internal method to initialize this NodeView as a {@link Gtk.Widget}
         */
        public override void realize() {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            var attr = Gdk.WindowAttr();
            attr.window_type = Gdk.WindowType.CHILD;
            attr.x = alloc.x;
            attr.y = alloc.y;
            attr.width = alloc.width;
            attr.height = alloc.height;
            attr.visual = this.get_visual();
            attr.event_mask = this.get_events()
                 | Gdk.EventMask.POINTER_MOTION_MASK
                 | Gdk.EventMask.BUTTON_PRESS_MASK
                 | Gdk.EventMask.BUTTON_RELEASE_MASK;
            Gdk.WindowAttributesType mask = Gdk.WindowAttributesType.X
                 | Gdk.WindowAttributesType.X
                 | Gdk.WindowAttributesType.VISUAL;
            var window = new Gdk.Window(this.get_parent_window(), attr, mask);
            this.set_window(window);
            this.register_window(window);
            this.set_realized(true);
        }
    }
}
