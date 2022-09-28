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
    public class Dock : Gtk.Widget {
        construct {
            set_css_name("gtkflow_dock");
        }

        public GFlow.Dock d {get; protected set;}
        private Gtk.GestureClick ctr_click;

        public Dock(GFlow.Dock d) {
            this.d = d;
            this.d.unlinked.connect(()=>{this.queue_draw();});
            this.d.linked.connect(()=>{this.queue_draw();});

            this.valign = Gtk.Align.CENTER;
            this.halign = Gtk.Align.CENTER;
            this.margin_start = 8;
            this.margin_end = 8;
            this.margin_top = 4;
            this.margin_bottom = 4;

            this.ctr_click = new Gtk.GestureClick();
            this.add_controller(this.ctr_click);
            this.ctr_click.pressed.connect((n, x, y) => { this.press_button(n,x,y); });
        }

        protected override void snapshot (Gtk.Snapshot sn) {
            var rect = Graphene.Rect().init(0,0,16, 16);
            var rrect = Gsk.RoundedRect().init_from_rect(rect, 8f);
            Gdk.RGBA color = {0.5f,0.5f,0.5f,1.0f};
            Gdk.RGBA[] border_color = {color,color,color,color};
            float[] thicc = {1f,1f,1f,1f};
            sn.append_border(rrect, thicc, border_color);
            base.snapshot(sn);
            var cr = sn.append_cairo(rect);
            cr.save();
            cr.set_source_rgba(0.0,0.0,0.0,0.0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.restore();
            if (this.d.is_linked()) {
                Gdk.RGBA black_color = {0.0f,0.0f,0.0f,1.0f};
                thicc = {8f, 8f, 8f, 8f};
                border_color = {black_color,black_color,black_color,black_color};
                cr.save();
                cr.set_source_rgba(0.0,0.0,0.0,1.0);
                cr.arc(8d,8d,4d,0.0,2*Math.PI);
                cr.fill();
                cr.restore();
            }
        }

        private void press_button(int n_clicked, double x, double y) {
            var nv = this.get_parent().get_parent() as NodeView;
            nv.start_temp_connector(this);
            nv.queue_allocate();
        }

        protected override  void measure(Gtk.Orientation o, int for_size, out int min, out int pref, out int min_base, out int pref_base) {
            min = 16;
            pref = 16;
            min_base = -1;
            pref_base = -1;
        }
    }
}
