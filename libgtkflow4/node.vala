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

    public delegate Gtk.Widget NodeTitleFactory(Node node);

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


    public class NodeDockLabelWidgetFactory : Object {

        public GFlow.Node node {
            get;
            private set;
        }

        public NodeDockLabelWidgetFactory(GFlow.Node node) {
            this.node = node;
        }

        public virtual Gtk.Widget create_dock_label(GFlow.Dock dock) {
            var label = new Gtk.Label(dock.name);
            label.justify = Gtk.Justification.LEFT;
            label.hexpand = true;
            if (dock is GFlow.Source) {
                label.halign = Gtk.Align.END;
            } else {
                label.halign = Gtk.Align.START;
            }
            return label;
        }
    }

    /**
     * A Simple node representation
     *
     * The default {@link NodeRenderer} that comes with libgtkflow. Use this
     * To wrap your {@link GFlow.Node}s in order to add them to a {@link NodeView}
     */
    public class Node : Gtk.Widget, NodeRenderer  {
        private static string CSS = "
        .gtkflow_node { 
            background: rgba(0.6, 0.6, 0.6, 0.2); 
            border-radius: 5px; 
            border: 1px solid rgba(128, 128, 128, 0.8); 
            box-shadow: 2px 2px 3px 3px rgba(153, 153, 153, 0.5);
        }

        .gtkflow_node_marked  { 
            background: rgba(0, 51, 128, 0.8); 
            border-radius: 5px; 
            border: 1px solid rgba(0, 51, 128, 0.8); 
            box-shadow: 2px 2px 3px 3px rgba(0, 51, 153, 0.5);
        }
        ";
        
        private static Gtk.CssProvider css = new Gtk.CssProvider();
        private static bool initialized = false;
        private static void init() {
            if (Node.initialized) return;
            Node.css.load_from_data(Node.CSS.data);
            Node.initialized = true;
        }

        construct {
            set_css_name("gtkflow_node");

            this.notify["marked"].connect(this.marked_changed);
        }

        private const int MARGIN_DEFAULT = 10;

        private Gtk.Grid grid;
        private Gtk.GestureClick ctr_click;
        public GFlow.Node n {get; protected set;}
        private NodeDockLabelWidgetFactory dock_label_factory;

        /**
         * {@inheritDoc}
         */
        public bool marked {get; internal set;}

        public Gdk.RGBA? highlight_color {get; set; default=null;}

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

        public bool render_resize_handle;
        private int n_docks = 0;
        private int margin = 0;

        ~Node() {
            this.grid.unparent();
        }

        /**
         * Instantiate a new node
         *
         * You are required to pass a {@link GFlow.Node} to this constructor.
         */
        public Node(GFlow.Node n) {
            this.with_margin(n, MARGIN_DEFAULT, new NodeDockLabelWidgetFactory(n));

            var title_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);

            var title_label = new Gtk.Label("");
            title_label.set_markup ("<b>%s</b>".printf(n.name));
            title_label.hexpand = true;
            title_label.halign = Gtk.Align.START;
            title_box.append(title_label);

            var delete_icon = new Gtk.Image.from_icon_name("edit-delete");
            var delete_button = new Gtk.Button();
            delete_button.child = delete_icon;
            delete_button.has_frame = false;
            delete_button.clicked.connect(this.remove);
            title_box.append(delete_button);

            set_title(title_box);
        }

        public Node.with_margin(GFlow.Node n, int margin, NodeDockLabelWidgetFactory dock_label_factory) {
            Node.init();
            this.n = n;
            this.dock_label_factory = dock_label_factory;
            this.margin = margin;
            
            this.add_css_class("gtkflow_node");
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

            this.grid.margin_top = this.margin;
            this.grid.margin_bottom = this.margin;
            this.grid.margin_start = this.margin;
            this.grid.margin_end = this.margin;
            this.grid.set_parent(this);

            this.set_layout_manager(new Gtk.BinLayout());

            this.ctr_click = new Gtk.GestureClick();
            this.add_controller(this.ctr_click);
            this.ctr_click.pressed.connect(this.press_button);
            this.ctr_click.end.connect(this.release_button);

            var motion_controller = new Gtk.EventControllerMotion();
            motion_controller.motion.connect(this.hover_over);
            this.add_controller(motion_controller);

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
            return this.margin;
        }

        public void remove() {
            var nv = this.get_parent() as NodeView;
            nv.remove(this);
        }

        /**
         * Adds a child widget to this node
         */
        public void add_child(Gtk.Widget child) {
            this.grid.attach(child, 0, 2 + n_docks, 3, 1);
        }

        public void set_title(Gtk.Widget title) {
            this.grid.attach(title, 0, 0, 3, 1);
        }

        /**
         * Removes a child widget from this node
         */
        public void remove_child(Gtk.Widget child) {
            child.unparent();
        }

        protected override void dispose() {
            this.grid.unparent();
            base.dispose();
        }

        /**
         * {@inheritDoc}
         */
        private void sink_added(GFlow.Sink s) {
            var dock = new Dock(s);
            var dock_label = dock_label_factory.create_dock_label(dock.d);
            
            this.grid.attach(dock, 0, 1 + ++n_docks, 1, 1);
            this.grid.attach(dock_label, 1, 1 + n_docks, 1, 1);
        }

        private void source_added(GFlow.Source s) {
            var dock = new Dock(s);
            var dock_label = dock_label_factory.create_dock_label(dock.d);

            this.grid.attach(dock, 2, 1 + ++n_docks, 1, 1);
            this.grid.attach(dock_label, 1, 1 + n_docks, 1, 1);
        }

        private void press_button(int n_click, double x, double y) {
            var picked_widget = this.pick(x,y, Gtk.PickFlags.NON_TARGETABLE);
            bool do_processing = true;
            if (picked_widget is GtkFlow.Dock ) {
                do_processing = false;
            }
            if (!do_processing) return;

            Gdk.Rectangle resize_area = {this.get_width()-8, this.get_height()-8,8,8};
            var nv = this.get_parent() as NodeView;
            if (this.n.resizable && resize_area.contains_point((int)x,(int)y)) {
                nv.resize_node = this;
                this.resize_start_width = this.get_width();
                this.resize_start_height = this.get_height();
            } else {
                nv.move_node = this;
            }
            this.click_offset_x = x;
            this.click_offset_y = y;
        }

        private void hover_over(double x, double y) {
            if (!this.n.resizable) {
                return;
            }

            Gdk.Rectangle resize_area = {this.get_width()-8, this.get_height()-8,8,8};
            if (resize_area.contains_point((int)x,(int)y)) {
                this.set_cursor_from_name("nwse-resize");
            } else {
                this.set_cursor_from_name("default");
            }
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

        private void marked_changed() {
            if (this.marked) {
                this.add_css_class("gtkflow_node_marked");
            } else {
                this.remove_css_class("gtkflow_node_marked");
            }
        }
    }
}
