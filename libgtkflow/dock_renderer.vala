namespace GtkFlow {
    public abstract class DockRenderer {
        public int dockpoint_height {get;set;default=16;}
        public int spacing_x {get; set; default=5;}
        public int spacing_y {get; set; default=3;}

        public abstract void draw_dock(Cairo.Context cr, 
                                         int offset_x, int offset_y, int width);
        public abstract int get_min_height();
        public abstract int get_min_width();
        public abstract void update_name_layout();
    }

    private class DefaultDockRenderer : DockRenderer {
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
            this.node.gnode.render_request.connect(()=>{
                this.update_name_layout();
            });
        }

        public override void update_name_layout() {
            string labelstring;
            if (this.node != null && this.node.node_view != null
                && this.node.node_view.show_types) {
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
        public override int get_min_height() {
            int width, height;
            this.layout.get_pixel_size(out width, out height);
            return (int)(Math.fmax(height, dockpoint_height))+spacing_y;
        }

        /**
         * Get the minimum height for this dock
         */
        public override int get_min_width() {
            int width, height;
            this.layout.get_pixel_size(out width, out height);
            return (int)(width + dockpoint_height + spacing_y);
        }

        public override void draw_dock(Cairo.Context cr, int offset_x, int offset_y, int width) {
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
}
