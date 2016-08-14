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
    public abstract class DockRenderer : GLib.Object {
        /**
         * Default value for the dock's dockpoint size.
         * Used for both height and width
         */
        public int dockpoint_height {get;set;default=16;}
        /**
         * Spacing between caption and dockpoint
         */
        public int spacing_x {get; set; default=5;}
        /**
         * Vertical spacing between docks
         */
        public int spacing_y {get; set; default=3;}

        /**
         * This signal is to be emitted whenever the size of this dock changes
         */
        public signal void size_changed();

        /**
         * Draw this dockrenderer's {@link GFlow.Dock} on the given
         * {@link Cairo.Context}
         */
        public abstract void draw_dock(Gtk.Widget w, Cairo.Context cr, Gtk.StyleContext sc,
                                         int offset_x, int offset_y, int width);
        /**
         * Implementations should return this dock's minimal height
         */
        public abstract int get_min_height();
        /**
         * Implementations should return this dock's minimal width
         */
        public abstract int get_min_width();
        /**
         * Implementations should update the graphical representation of the
         * dock's captionstring and typestring. If typestrings should be displayed,
         * the parameter show_types will be true
         */
        public abstract void update_name_layout(bool show_types);
        /**
         * Return the dock that belongs to this dockrenderer
         */
        public abstract GFlow.Dock get_dock();
    }

    private class DefaultDockRenderer : DockRenderer {
        private Pango.Layout layout = null;
        private GFlow.Dock d = null;

        public DefaultDockRenderer(Node n, GFlow.Dock d) {
            this.d = d;
            this.layout = (new Gtk.Label("")).create_pango_layout("");
        }

        public override GFlow.Dock get_dock () {
            return this.d;
        }

        public override void update_name_layout(bool show_types) {
            string labelstring;
            string name = this.d.name ?? "";
            string typename = this.d.typename ?? this.d.determine_typestring();
            if (show_types) {
                labelstring = "<i>%s</i> : %s".printf( typename, name );
            } else {
                labelstring = name;
            }
            this.layout.set_markup(labelstring, -1);
            this.size_changed();
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

        public override void draw_dock(Gtk.Widget w, Cairo.Context cr, Gtk.StyleContext sc,
                                       int offset_x, int offset_y, int width) {
            var rb = new Gtk.RadioButton(null);
            if (d is GFlow.Sink)
                draw_sink(w, cr, sc, offset_x, offset_y, width);
            if (d is GFlow.Source)
                draw_source(w, cr, sc, offset_x, offset_y, width);
        }

        /**
         * Draw the given source onto a cairo context
         */
        public void draw_source(Gtk.Widget w, Cairo.Context cr, Gtk.StyleContext sc,
                                int offset_x, int offset_y, int width) {
            Gtk.StateFlags flags = Gtk.StateFlags.NORMAL;
            if (this.d.is_linked())
                flags = Gtk.StateFlags.CHECKED;
            if (this.d.highlight)
                flags |= Gtk.StateFlags.PRELIGHT;
            if (this.d.active)
                flags |= Gtk.StateFlags.ACTIVE;
            
            int option_height=16;
            int option_width=16;
            int option_x=offset_x+width-dockpoint_height;
            int option_y=offset_y;
            draw_radio(w, cr, &option_x, &option_y,
                       flags, &option_height, &option_width);
            stdout.printf("x:%i y:%i w:%i h:%i\n", option_x, option_y, option_width, option_height);
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
        public void draw_sink(Gtk.Widget w, Cairo.Context cr, Gtk.StyleContext sc,
                              int offset_x, int offset_y, int width) {
            Gtk.StateFlags flags = Gtk.StateFlags.NORMAL;
            if (this.d.is_linked())
                flags = Gtk.StateFlags.CHECKED;
            if (this.d.highlight)
                flags |= Gtk.StateFlags.PRELIGHT;
            if (this.d.active)
                flags |= Gtk.StateFlags.ACTIVE;
            int option_height=16;
            int option_width=16;
            int option_x=offset_x;
            int option_y=offset_y;
            draw_radio(w, cr, &option_x, &option_y, 
                       flags, &option_height, &option_width);
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
