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

    public errordomain NodeError {
        TITLE_ALREADY_INITIALIZED;
    }

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
        private const double DRAG_THRESHOLD = 5.0;

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

        private bool title_initialized = false;

        construct {
            set_css_name("gtkflow_node");

            this.notify["marked"].connect(this.marked_changed);
        }

        private const int MARGIN_DEFAULT = 10;

        private Gtk.Grid pads_grid;
        private Gtk.Box node_box;
        private Gtk.GestureDrag drag_gesture;
        private double drag_start_x;
        private double drag_start_y;
        private bool drag_active;
        private bool allow_drag;

        private int previous_x;
        private int previous_y;
        private int previous_width;
        private int previous_height;

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

        public signal void position_changed(int old_x, int old_y, int new_x, int new_y);
        public signal void size_changed(int old_width, int old_height, int new_width, int new_height);

        private int n_docks = 0;
        private int margin = 0;

        ~Node() {
            this.pads_grid.unparent();
            this.node_box.unparent();
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

            try {
                set_title(title_box);
            } catch (NodeError e) {
                error("Could not set title in node: %s", e.message);
            }
        }

        public Node.with_margin(GFlow.Node n, int margin, NodeDockLabelWidgetFactory dock_label_factory) {
            Node.init();
            this.n = n;
            this.dock_label_factory = dock_label_factory;
            this.margin = margin;
            
            this.set_layout_manager(new Gtk.BinLayout());
            this.add_css_class("gtkflow_node");
            this.get_style_context().add_provider(Node.css,Gtk.STYLE_PROVIDER_PRIORITY_USER);

            this.node_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            this.node_box.set_parent(this);
            this.node_box.hexpand = true;
            this.node_box.vexpand = true;
            this.node_box.halign = Gtk.Align.FILL;
            this.node_box.valign = Gtk.Align.FILL;

            this.node_box.margin_top = this.margin;
            this.node_box.margin_bottom = this.margin;
            this.node_box.margin_start = this.margin;
            this.node_box.margin_end = this.margin;

            create_pads_grid();
            create_drag_drop_controller();
            create_motion_controller();
            create_event_override_controller();
        }

        private void create_event_override_controller() {
            var controller = new Gtk.EventControllerLegacy();
            controller.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);
            controller.event.connect((ev) => {
                if (drag_active &&
                    (ev.get_event_type() == Gdk.EventType.BUTTON_PRESS ||
                    ev.get_event_type() == Gdk.EventType.BUTTON_RELEASE ||
                    ev.get_event_type() == Gdk.EventType.DRAG_ENTER)) {
                    return Gdk.EVENT_STOP;
                }
                return Gdk.EVENT_PROPAGATE;
            });
            this.add_controller(controller);
        }

        private void create_drag_drop_controller() {
            this.drag_gesture = new Gtk.GestureDrag();
            this.add_controller(this.drag_gesture);
            this.drag_gesture.drag_begin.connect(this.on_drag_begin);
            this.drag_gesture.drag_update.connect(this.on_drag_update);
            this.drag_gesture.drag_end.connect(this.on_drag_end);
        }

        private void create_motion_controller() {
            var motion_controller = new Gtk.EventControllerMotion();
            motion_controller.motion.connect(this.hover_over);
            this.add_controller(motion_controller);
        }

        private void create_pads_grid() {
            this.pads_grid = new Gtk.Grid();
            this.pads_grid.column_homogeneous = false;
            this.pads_grid.column_spacing = 5;
            this.pads_grid.row_homogeneous = false;
            this.pads_grid.row_spacing = 5;

            node_box.append(this.pads_grid);

            foreach (GFlow.Source s in n.get_sources()) {
                this.source_added(s);
            }
            foreach (GFlow.Sink s in n.get_sinks()) {
                this.sink_added(s);
            }

            this.n.source_added.connect(this.source_added);
            this.n.source_removed.connect(this.source_removed);
            this.n.sink_added.connect(this.sink_added);
            this.n.sink_removed.connect(this.sink_removed);
        }

        /**
         * Retrieve a Dock-Widget from this node.
         *
         * Gives you the GtkFlow.Dock-object that corresponds to the given
         * GFlow.Dock. Returns null if the searched Dock is not associated
         * with any of the Dock-Widgets in this node.
         */
        public Dock? retrieve_dock (GFlow.Dock d) {
            var c = this.pads_grid.get_first_child();
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
            this.node_box.append(child);
        }

        public void set_title(Gtk.Widget title) throws NodeError {
            if (!this.title_initialized) {
                this.pads_grid.attach(title, 0, 0, 3, 1);
                this.title_initialized = true;
            } else {
                throw new NodeError.TITLE_ALREADY_INITIALIZED("Title may only be initialized once");
            }
        }

        /**
         * Removes a child widget from this node
         */
        public void remove_child(Gtk.Widget child) {
            child.unparent();
        }

        protected override void dispose() {
            this.pads_grid.unparent();
            base.dispose();
        }

        /**
         * {@inheritDoc}
         */
        private void sink_added(GFlow.Sink s) {
            var dock = new Dock(s);
            var dock_label = dock_label_factory.create_dock_label(dock.d);
            
            this.pads_grid.attach(dock, 0, 1 + ++n_docks, 1, 1);
            this.pads_grid.attach(dock_label, 1, 1 + n_docks, 1, 1);
        }

        private void sink_removed(GFlow.Sink s) {
            var dock_widget = retrieve_dock(s);

            int column = -1;
            int row = -1;
            int width, height = 0;
            pads_grid.query_child(dock_widget, out column, out row, out width, out height);

            if (row != -1) {
                pads_grid.remove_row(row);
            }
        }

        private void source_added(GFlow.Source s) {
            var dock = new Dock(s);
            var dock_label = dock_label_factory.create_dock_label(dock.d);

            this.pads_grid.attach(dock, 2, 1 + ++n_docks, 1, 1);
            this.pads_grid.attach(dock_label, 1, 1 + n_docks, 1, 1);
        }

        private void source_removed(GFlow.Source s) {
            var dock_widget = retrieve_dock(s);

            int column = -1;
            int row = -1;
            int width, height = 0;
            pads_grid.query_child(dock_widget, out column, out row, out width, out height);

            if (row != -1) {
                pads_grid.remove_row(row);
            }
        }

        /**
         * Programmatically set a node's position
         */
        public void set_position(int x, int y) {
            var parent = this.get_parent();
            if (!(parent is NodeView)) {
                warning("Node is not a child of a NodeView");
                return;
            }
            var nodeview = parent as NodeView;
            var layout_child = nodeview.layout_manager.get_layout_child(this) as NodeViewLayoutChild;
            layout_child.x = x;
            layout_child.y = y;

            if (this.marked) {
                foreach (NodeRenderer n in nodeview.get_marked_nodes()) {
                    if (n != this) continue;
                    var mlc = nodeview.layout_manager.get_layout_child(n) as NodeViewLayoutChild;
                    mlc.x -= x;
                    mlc.y -= y;
                }
            }
        }

        public void get_position(out int x, out int y) {
            var parent = this.get_parent();
            if (!(parent is NodeView)) {
                x = 0;
                y = 0;
                warning("Node is not a child of a NodeView");
                return;
            }


            var nodeview = parent as NodeView;
            var layout_child = nodeview.layout_manager.get_layout_child(this) as NodeViewLayoutChild;

            x = layout_child.x;
            y = layout_child.y;
        }

        private void hover_over(double x, double y) {
            if (!this.n.resizable || this.drag_active) {
                return;
            }

            Gdk.Rectangle resize_area = resize_area();
            if (resize_area.contains_point((int)x,(int)y)) {
                this.set_cursor_from_name("nwse-resize");
            } else {
                this.set_cursor_from_name("default");
            }
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

        private Gdk.Rectangle resize_area() {
            return {
                this.get_width() - 16, 
                this.get_height() - 16,
                16,
                16
            };
        }

        private void on_drag_begin(double start_x, double start_y) {
            var picked = this.pick(start_x, start_y, Gtk.PickFlags.DEFAULT);
            if (!can_drag(picked)) {
                this.allow_drag = false;
                this.drag_active = false;

                reset_cursor();
                return;
            }

            this.allow_drag = true;
            this.drag_start_x = start_x;
            this.drag_start_y = start_y;
            this.drag_active = false;

            var node_view = this.get_parent() as NodeView;
            if (node_view == null) return;
        
            var layout_child = node_view.layout_manager.get_layout_child(this) as NodeViewLayoutChild;
            this.previous_x = layout_child.x;
            this.previous_y = layout_child.y;
            this.previous_width = get_width();
            this.previous_height = get_height();

            set_cursor("move");
        }

        private bool can_drag(Gtk.Widget? picked) {
            if (picked == null)
                return false;
        
            Gtk.Widget? current = picked;
            while (current != null) {
                if (current is Dock)
                    return false;
        
                current = current.get_parent();
            }
        
            return true;
        }

        private void on_drag_update(double offset_x, double offset_y) {
            var node_view = this.get_parent() as NodeView;
            if (node_view == null)
                return;

            if (!allow_drag) return;

            Gdk.Rectangle resize_area = resize_area();
            if (!this.drag_active) {
                bool in_resize_zone = this.n.resizable && resize_area.contains_point((int)this.drag_start_x, (int)this.drag_start_y);
                if (!in_resize_zone && below_drag_treshold(offset_x, offset_y)) {
                    return;
                }

                this.drag_active = true;
                this.click_offset_x = this.drag_start_x; 
                this.click_offset_y = this.drag_start_y;

                if (this.n.resizable && resize_area.contains_point(
                        (int)(this.click_offset_x + offset_x),
                        (int)(this.click_offset_y + offset_y))) {
                    node_view.resize_node = this;
                    this.resize_start_width = this.get_width();
                    this.resize_start_height = this.get_height();
                } else {
                    node_view.move_node = this;
                }
            }

            if (node_view.move_node == this) {
                var layout_child = node_view.layout_manager.get_layout_child(this) as NodeViewLayoutChild;
                layout_child.x += (int)offset_x;
                layout_child.y += (int)offset_y;
                node_view.queue_allocate();
            }

            if (node_view.resize_node == this) {
                int new_width = (int)(this.resize_start_width + offset_x);
                int new_height = (int)(this.resize_start_height + offset_y);
                this.set_size_request(new_width, new_height);
            }
        }

        private bool below_drag_treshold(double offset_x, double offset_y) {
            if (Math.fabs(offset_x) < DRAG_THRESHOLD && Math.fabs(offset_y) < DRAG_THRESHOLD) {
                return true;
            }
            return false;
        }
        
        private void on_drag_end(double offset_x, double offset_y) {
            reset_cursor();

            if (!allow_drag) return;
            
            var node_view = this.get_parent() as NodeView;
            if (node_view == null) return;
        
            node_view.move_node = null;
            node_view.resize_node = null;
            this.drag_active = false;

            node_view.queue_allocate();

            var layout_child = node_view.layout_manager.get_layout_child(this) as NodeViewLayoutChild;
            notify_position_changed(previous_x, previous_y, layout_child.x, layout_child.y);
            notify_size_changed(previous_width, previous_height, get_width(), get_height());
        }

        private void notify_position_changed(int old_x, int old_y, int new_x, int new_y) {
            if (old_x == new_x && old_y == new_y) return;
            position_changed(old_x, old_y, new_x, new_y);
        }

        private void notify_size_changed(int old_width, int old_height, int new_width, int new_height) {
            if (old_width == new_width && old_height == new_height) return;
            size_changed(old_width, old_height, new_width, new_height);
        }

        private new void set_cursor(string? cursor_name) {
            var native = this.get_native();
            if (native != null) {
                var surface = native.get_surface();

                if (cursor_name == null) {
                    surface.set_cursor(null);
                    return;
                }
    
                var cursor = new Gdk.Cursor.from_name("move", null);
                if (surface != null)
                    surface.set_cursor(cursor);
            }
        }

        private void reset_cursor() {
            set_cursor(null);
        }
    }
}
