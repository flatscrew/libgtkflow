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
     * Defines an object that can be added to a Nodeview
     *
     * Implement this if you want custom nodes that have their own
     * drawing routines and special behaviour
     */
    public interface NodeRenderer : Gtk.Widget {
        /**
         * The {@link GFlow.Node} that this Node represents
         */
        public abstract GFlow.Node n {get; protected set;}
        /**
         * Expresses wheter this node is marked via rubberband selection
         */
        public abstract bool marked {get; internal set;}
        /**
         * Returns a {@link Dock} if the given {@link GFlow.Dock} resides
         * in this node.
         */
        public abstract Dock? retrieve_dock(GFlow.Dock d);
        /**
         * Returns the value of this node's margin
         */
        public abstract int get_margin();
        /**
         * Click offset: x coordinate
         *
         * Holds the offset-position relative to the origin of the
         * node at which this node has been clicked the last time.
         */
        public abstract double click_offset_x {get; protected set; default=0;}
        /**
         * Click offset: y coordinate
         *
         * Holds the offset-position relative to the origin of the
         * node at which this node has been clicked the last time.
         */
        public abstract double click_offset_y {get; protected set; default=0;}

        /**
         * Resize start width
         *
         * Hold the original width of the node when the last resize process
         * had been started
         */
        public abstract double resize_start_width {get; protected set; default=0;}
        /**
         * Resize start height
         *
         * Hold the original height of the node when the last resize process
         * had been started
         */
        public abstract double resize_start_height {get; protected set; default=0;}
    }

    
    /**
     * A Simple node representation
     *
     * The default {@link NodeRenderer} that comes with libgtkflow. Use this
     * To wrap your {@link GFlow.Node}s in order to add them to a {@link NodeView}
     */
    public class Node : Gtk.Widget, NodeRenderer  {
        private static string CSS = ".gtkflow_node { background: rgba(0.6,0.6,0.6,0.2); border-radius: 5px; }";
        private static Gtk.CssProvider css = new Gtk.CssProvider();
        private static bool initialized = false;
        private static void init() {
            if (Node.initialized) return;
            Node.css.load_from_data(Node.CSS.data);
            Node.initialized = true;
        }

        construct {
            set_css_name("gtkflow_node");
        }

        public const int MARGIN = 10;

        private Gtk.Grid grid;
        private Gtk.GestureClick ctr_click;
        public GFlow.Node n {get; protected set;}

        /**
         * {@inheritDoc}
         */
        public bool marked {get; internal set;}
        /**
         * User-controlled node resizability
         *
         * Set to true if this should be resizable
         */
        public bool resizable {get; set; default=true;}

        public Gdk.RGBA? highlight_color {get; set; default=null;}

        /**
         * A widget to use for the node title instead of the name-label
         *
         * TODO: implement
         */
        public Gtk.Widget title_widget {get; set;}
        private Gtk.Label title_label;
        private Gtk.Button delete_button;

        /**
         * {@inheritDoc}
         */
        public double click_offset_x {get; protected set; default=0;}
        /**
         * {@inheritDoc}
         */
        public double click_offset_y {get; protected set; default=0;}
        /**
         * {@inheritDoc}
         */
        public double resize_start_width {get; protected set; default=0;}
        /**
         * {@inheritDoc}
         */
        public double resize_start_height {get; protected set; default=0;}

        // TODO: implement individual widgets as dock labels
        // private HashTable<GFlow.Dock, Gtk.Widget> widgets;

        private int n_docks = 0;

        /**
         * Instantiate a new node
         *
         * You are required to pass a {@link GFlow.Node} to this constructor.
         */
        public Node(GFlow.Node n) {
            Node.init();
            this.n = n;
            
            this.get_style_context().add_class("gtkflow_node");
            this.get_style_context().add_provider(Node.css,Gtk.STYLE_PROVIDER_PRIORITY_USER);

            this.grid = new Gtk.Grid();
            this.grid.column_homogeneous = false;
            this.grid.column_spacing = 5;
            this.grid.row_homogeneous = false;
            this.grid.row_spacing = 5;
            this.grid.hexpand = true;
            this.grid.vexpand = true;
            this.grid.halign = Gtk.Align.FILL;
            this.grid.valign = Gtk.Align.FILL;

            this.grid.margin_top = Node.MARGIN;
            this.grid.margin_bottom = Node.MARGIN;
            this.grid.margin_start = Node.MARGIN;
            this.grid.margin_end = Node.MARGIN;
            this.grid.set_parent(this);

            this.set_layout_manager(new Gtk.BinLayout());

            this.ctr_click = new Gtk.GestureClick();
            this.add_controller(this.ctr_click);
            this.ctr_click.pressed.connect((n, x, y) => { this.press_button(n,x,y); });
            this.ctr_click.end.connect(() => { this.release_button(); });

            this.title_label = new Gtk.Label("");
            this.title_label.set_markup ("<b>%s</b>".printf(n.name));
            this.grid.attach(this.title_label, 0, 0, 2, 1);
            this.n.notify["name"].connect(()=>{
                this.title_label.set_markup("<b>%s</b>".printf(n.name));
            });

            var delete_icon = new Gtk.Image.from_icon_name("edit-delete");
            this.delete_button = new Gtk.Button();
            this.delete_button.child = delete_icon;
            this.delete_button.has_frame = false;
            this.delete_button.clicked.connect(this.cb_delete);
            this.grid.attach(this.delete_button, 2, 0, 1, 1);

            foreach (GFlow.Source s in n.get_sources()) {
                this.source_added(s);
            }
            foreach (GFlow.Sink s in n.get_sinks()) {
                this.sink_added(s);
            }
        }

        /**
         * Retrieve a Dock-Widget from this node.
         *
         * Gives you the GtkFlow.Dock-object that corresponds to the given
         * GFlow.Dock. Returns null if the searched Dock is not associated
         * with any of the Dock-Widgets in this node.
         */
        public Dock? retrieve_dock (GFlow.Dock d) {
            var c = this.grid.get_first_child();
            while (c != null) {
                if (!(c is Dock)) {
                    c = c.get_next_sibling();
                    continue;
                }
                var dw = (Dock)c;
                if (dw.d == d) return dw;
                c = c.get_next_sibling();
            }
            return null;
        }

        /**
         * {@inheritDoc}
         */
        public int get_margin() {
            return Node.MARGIN;
        }

        private void cb_delete() {
            var nv = this.get_parent() as NodeView;
            nv.remove(this);
        }

        /**
         * Adds a child widget to this node
         */
        public void add_child(Gtk.Widget child) {
            this.grid.attach(child, 0, 2 + n_docks, 3, 1);
        }

        /**
         * Removes a child widget from this node
         */
        public void remove_child(Gtk.Widget child) {
            child.unparent();
        }

        /**
         * {@inheritDoc}
         */
        public override void dispose() {
            this.grid.unparent();
            base.dispose();
        }


        private void sink_added(GFlow.Sink s) {
            var dock = new Dock(s);
            dock.notify["label"].connect(()=> {
                var lc = (Gtk.GridLayoutChild)this.grid.get_layout_manager().get_layout_child(dock);
                this.grid.attach(dock.label, 1, lc.row, 1, 1);
            });
            this.grid.attach(dock, 0, 1 + ++n_docks, 1, 1);
            this.grid.attach(dock.label, 1, 1 + n_docks, 1, 1);
        }

        private void source_added(GFlow.Source s) {
            var dock = new Dock(s);
            dock.notify["label"].connect(()=> {
                var lc = (Gtk.GridLayoutChild)this.grid.get_layout_manager().get_layout_child(dock);
                this.grid.attach(dock.label, 1, lc.row, 1, 1);
            });
            this.grid.attach(dock, 2, 1 + ++n_docks, 1, 1);
            this.grid.attach(dock.label, 1, 1 + n_docks, 1, 1);
        }

        private void press_button(int n_click, double x, double y) {
            var picked_widget = this.pick(x,y, Gtk.PickFlags.NON_TARGETABLE);

            bool do_processing = false;
            if (picked_widget == this || picked_widget == this.grid) {
                do_processing = true;
            } else if (picked_widget.get_parent() == this.grid) {
                if (picked_widget is Gtk.Label || picked_widget is Gtk.Image) {
                    do_processing = true;
                }
            }
            if (!do_processing) return;

            Gdk.Rectangle resize_area = {this.get_width()-8, this.get_height()-8,8,8};
            var nv = this.get_parent() as NodeView;
            if (resize_area.contains_point((int)x,(int)y)) {
                nv.resize_node = this;
                this.resize_start_width = this.get_width();
                this.resize_start_height = this.get_height();
            } else {
                nv.move_node = this;
            }
            this.click_offset_x = x;
            this.click_offset_y = y;
        }

        private void release_button() {
            var nv = this.get_parent() as NodeView;
            nv.move_node = null;
            nv.resize_node = null;
            nv.queue_allocate();
        }

        /**
         * {@inheritDoc}
         */
        public new void set_parent(Gtk.Widget w) {
            if (!(w is NodeView)) {
                warning("Trying to add a GtkFlow.Node to something that is not a GtkFlow.NodeView!");
                return;
            }
            base.set_parent(w);
        }

        protected override void snapshot (Gtk.Snapshot sn) {
            var rect = Graphene.Rect().init(0,0,this.get_width(), this.get_height());
            var rrect = Gsk.RoundedRect().init_from_rect(rect, 5f);
            Gdk.RGBA color;
            Gdk.RGBA grey_color;
            if (this.marked) {
                color = {0.0f,0.2f,0.5f,0.8f};
                grey_color = {0.0f,0.2f,0.6f,0.5f};
                sn.append_color(grey_color ,rect );
            } else {
                color = {0.5f,0.5f,0.5f,0.8f};
                grey_color = {0.6f,0.6f,0.6f,0.5f};
            }
            Gdk.RGBA[] border_color = {color,color,color,color};
            float[] thicc = {1f,1f,1f,1f};
            if (this.highlight_color != null) {
                sn.append_color(this.highlight_color ,rect );
            }
            sn.append_border(rrect, thicc, border_color);
            sn.append_outset_shadow(rrect, grey_color, 2f, 2f, 3f, 3f);
            if (this.resizable) {
                var cr = sn.append_cairo(rect);
                cr.save();
                cr.set_source_rgba(0.6,0.6,0.6,0.9);
                cr.set_line_width(8.0);
                cr.move_to(this.get_width()+2,this.get_height()-6);
                cr.line_to(this.get_width()-6,this.get_height()+2);
                cr.stroke();
                cr.restore();
            }
            base.snapshot(sn);
        }
    }
}
