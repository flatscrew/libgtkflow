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
    /**
     * A Gtk Widget that shows nodes and their connections to the user
     * It also lets the user edit said connections.
     */
    public class NodeView : Gtk.Container, Gtk.Scrollable {
        private List<Node> nodes = new List<Node>();
   
        // The node that is currently being dragged around
        private const int DRAG_THRESHOLD = 3;
        private Node? drag_node = null;
        private bool drag_threshold_fulfilled = false;
        // Coordinates where the drag started
        private double drag_start_x = 0;
        private double drag_start_y = 0;
        // Difference from the chosen drag-point to the 
        // upper left corner of the drag_node
        private int drag_diff_x = 0;
        private int drag_diff_y = 0;

        // Remember if a closebutton was pressed
        private bool close_button_pressed = false;
        // Remember if we are resizing a node
        private Node? resize_node = null;
        private int resize_start_x = 0;
        private int resize_start_y = 0;

        // Remember the last dock the mouse hovered over, so we can unhighlight it
        private GFlow.Dock? hovered_dock = null;

        // The dock that we are targeting for dragging a new connector
        private GFlow.Dock? drag_dock = null;
        // The dock that we are targeting to drop a connector on
        private GFlow.Dock? drop_dock = null;
        // The connector that is being used to draw a non-established connection
        private Gtk.Allocation? temp_connector = null;

        /**
         * Determines whether docks should render type-indicators
         */
        public bool show_types {get; set; default=false;}

        public Gtk.Adjustment _hadjustment = null;
        public Gtk.Adjustment hadjustment {
            get {
                return this._hadjustment;
            }
            set {
                this._hadjustment = value;
                this._hadjustment.value_changed.connect(this.queue_draw);
            }
        }
        public Gtk.Adjustment _vadjustment = null;
        public Gtk.Adjustment vadjustment {
            get {
                return this._vadjustment;

            }
            set {
                this._vadjustment = value;
                this._vadjustment.value_changed.connect(this.queue_draw);
            }
        }
        public Gtk.ScrollablePolicy hscroll_policy {get; set;
                                                    default=Gtk.ScrollablePolicy.MINIMUM;}
        public Gtk.ScrollablePolicy vscroll_policy {get; set;
                                                    default=Gtk.ScrollablePolicy.MINIMUM;}

        /**
         * Determines whether the displayed Nodes can be edited by the user
         * e.g. alter their positions by dragging and dropping or drawing
         * new collections or erasing old ones
         */
        public bool editable {get; set; default=true;}

        public NodeView() {
            Object();
            this.vadjustment = new Gtk.Adjustment(0, 0, 100, 50, 100, 100);
            this.hadjustment = new Gtk.Adjustment(0, 0, 100, 50, 100, 100);
            this.set_size_request(100,100);
            this.notify["show-types"].connect(()=>{this.render_all();});
        }

        private void add_common(Node n) {
            if (this.nodes.index(n) == -1) {
                this.nodes.insert(n,0);
                n.node_view = this;
                this.add(n as Gtk.Widget);
            }
            this.queue_draw();
            n.set_parent(this);
        }

        private void render_all() {
            foreach (Node n in this.nodes)
                n.render_all();
            this.queue_draw();
        }

        public void add_node(GFlow.Node gn) {
            Node n = new Node(gn);
            this.add_common(n);
        }

        public void add_with_child(GFlow.Node gn, Gtk.Widget child) {
            Node n = new Node.with_child(gn, child);
            this.add_common(n);
        }

        public void set_node_renderer(GFlow.Node gn, NodeRenderer nr) {
            Node n = this.get_node_from_gflow_node(gn);
            n.node_renderer = nr;
            this.queue_draw();
        }

        /**
         * Use this method to register childwidgets for custom node
         * renderes to the node.
         */
        public void register_child(GFlow.Node gn, Gtk.Widget child) {
            Node n = this.get_node_from_gflow_node(gn);
            if (n != null) {
                n.add(child);
            }
        }

        /**
         * Use this method to register childwidgets for custom node
         * renderes to the node.
         */
        public void unregister_child(GFlow.Node gn, Gtk.Widget child) {
            Node n = this.get_node_from_gflow_node(gn);
            if (n != null) {
                n.remove(child);
            }
        }

        public override void add(Gtk.Widget w) {
            warning("You can only add GFlow.Nodes to GtkFlow.NodeViews. "
                   +"Please use NodeView.add_node or NodeView.add_node_with_child");
        }

        public override void remove(Gtk.Widget w) {
            warning("You can only remove GFlow.Nodes to GtkFlow.NodeViews. "
                   +"Please use NodeView.remove_node");
        }

        private Node? get_node_from_gflow_node(GFlow.Node gn) {
            foreach (Node n in this.nodes) {
                if (n.gnode == gn) {
                    return n;
                }
            }
            return null;
        }

        private void remove_node(GFlow.Node n) {
            Node gn = this.get_node_from_gflow_node(n);
            if (this.nodes.index(gn) != -1) {
                this.nodes.remove(gn);
                gn.node_view = null;
                this.remove(gn as Gtk.Widget);
            }
            this.queue_draw();
        }

        private Node? get_node_on_position(double x,double y) {
            Gtk.Allocation alloc;
            x += this.hadjustment.value;
            y += this.vadjustment.value;
            foreach (Node n in this.nodes) {
                n.get_node_allocation(out alloc);
                if ( x >= alloc.x && y >= alloc.y &&
                         x <= alloc.x + alloc.width && y <= alloc.y + alloc.height ) {
                    return n;
                }
            }
            return null;
        }

        public override bool button_press_event(Gdk.EventButton e) {
            if (!this.editable)
                return false;
            Node? n = this.get_node_on_position(e.x, e.y);
            GFlow.Dock? targeted_dock = null;
            Gdk.Point pos = {(int)e.x,(int)e.y};
            if (n != null) {
                Gtk.Allocation alloc;
                n.get_node_allocation(out alloc);
                bool cbp = n.node_renderer.is_on_closebutton(
                    pos, alloc,
                    (int)this.hadjustment.value,
                    (int)this.vadjustment.value,
                    n.border_width
                );
                if (cbp)
                    this.close_button_pressed = true;
                targeted_dock = n.node_renderer.get_dock_on_position(
                    pos, n.get_dock_renderers(),
                    (int)this.hadjustment.value,
                    (int)this.vadjustment.value,
                    n.border_width, alloc
                );
                if (targeted_dock != null) {
                    this.drag_dock = targeted_dock;
                    this.drag_dock.active = true;
                    int startpos_x = 0, startpos_y = 0;
                    if (this.drag_dock is GFlow.Sink && this.drag_dock.is_connected()){
                        GFlow.Source s = (this.drag_dock as GFlow.Sink).source;
                        Node srcnode = this.get_node_from_gflow_node(s.node);
                        Gtk.Allocation src_alloc;
                        srcnode.get_node_allocation(out src_alloc);
                        if (!srcnode.node_renderer.get_dock_position(
                                s, srcnode.get_dock_renderers(),
                                (int)this.hadjustment.value,
                                (int)this.vadjustment.value,
                                (int)srcnode.border_width, src_alloc,
                                out startpos_x, out startpos_y )) {
                            warning("No dock on position. Aborting drag");
                            return false;
                        }
                        Gdk.Point startpos = {startpos_x,startpos_y};
                        this.temp_connector = {startpos.x, startpos.y,
                                               (int)e.x-startpos.x, (int)e.y-startpos.y};
                    } else {
                        if (!n.node_renderer.get_dock_position(
                                this.drag_dock, n.get_dock_renderers(),
                                (int)this.hadjustment.value,
                                (int)this.vadjustment.value,
                                (int)n.border_width, alloc,
                                out startpos_x, out startpos_y )) {
                            warning("No dock on position. Aborting drag");
                            return false;
                        }
                        Gdk.Point startpos = {startpos_x,startpos_y};
                        this.temp_connector = {startpos.x, startpos.y, 0, 0};
                    }
                    this.queue_draw();
                    return true;
                }
            }
            // Set a new drag node.
            if (n != null) {
                Gtk.Allocation alloc;
                n.get_node_allocation(out alloc);
                bool on_resize = n.node_renderer.is_on_resize_handle(
                    pos, alloc,
                    (int)this.hadjustment.value,
                    (int)this.vadjustment.value,
                    n.border_width
                );

                if (on_resize && this.resize_node == null) {
                    this.resize_node = n;
                    this.resize_node.get_node_allocation(out alloc);
                    this.resize_start_x = alloc.width;
                    this.resize_start_y = alloc.height;
                } else if (this.resize_node == null && this.drag_node == null) {
                    this.drag_node = n;
                    this.drag_node.get_node_allocation(out alloc);
                } else {
                    return false;
                }
                this.drag_start_x = e.x;
                this.drag_start_y = e.y;
                this.drag_diff_x = (int)this.drag_start_x - alloc.x;
                this.drag_diff_y = (int)this.drag_start_y - alloc.y;
            }
            return false;
        }

        public override bool button_release_event(Gdk.EventButton e) {
            if (!this.editable)
                return false;
            // Determine if this was a closebutton press
            if (this.close_button_pressed) {
                Node? n = this.get_node_on_position(e.x, e.y);
                if (n != null) {
                    Gdk.Point pos = {(int)e.x,(int)e.y};
                    Gtk.Allocation alloc;
                    n.get_node_allocation(out alloc);
                    bool cbp = n.node_renderer.is_on_closebutton(
                        pos, alloc,
                        (int)this.hadjustment.value,
                        (int)this.vadjustment.value,
                        n.border_width
                    );
                    if (cbp) {
                        n.gnode.disconnect_all();
                        this.remove_node(n.gnode);
                        assert (n is Gtk.Widget);
                        (n as Gtk.Widget).destroy();
                        this.queue_draw();
                        this.close_button_pressed = false;
                        return true;
                    }
                }
            }
            // Try to build a new connection
            if (this.drag_dock != null) {
                try {
                    if (this.drag_dock is GFlow.Source && this.drop_dock is GFlow.Sink) {
                        (this.drag_dock as GFlow.Source).connect(this.drop_dock as GFlow.Sink);
                    }
                    else if (this.drag_dock is GFlow.Sink && this.drop_dock is GFlow.Source) {
                        (this.drop_dock as GFlow.Source).connect(this.drag_dock as GFlow.Sink);
                    }
                    else if (this.drag_dock is GFlow.Sink && this.drop_dock is GFlow.Sink) {
                        GFlow.Source? src = (this.drag_dock as GFlow.Sink).source;
                        if (src != null) {
                            src.disconnect(this.drag_dock as GFlow.Sink);
                            src.connect(this.drop_dock as GFlow.Sink);
                        }
                    }
                    else if (this.drag_dock is GFlow.Sink && this.drop_dock == null) {
                        GFlow.Source? src = (this.drag_dock as GFlow.Sink).source;
                        if (src != null) {
                            src.disconnect(this.drag_dock as GFlow.Sink);
                        }
                    }
                } catch (GFlow.NodeError e) {
                    warning(e.message);
                }
            }
            this.stop_dragging();
            this.queue_draw();
            return false;
        }

        private void stop_dragging() {
            this.drag_start_x = 0;
            this.drag_start_y = 0;
            this.drag_diff_x = 0;
            this.drag_diff_y = 0;
            this.drag_node = null;
            if (this.drag_dock != null) {
                this.drag_dock.active = false;
            }
            this.drag_dock = null;
            if (this.drop_dock != null) {
                this.drop_dock.active = false;
            }
            this.drop_dock = null;
            this.temp_connector = null;
            this.drag_threshold_fulfilled = false;
            this.resize_node = null;
            this.get_window().set_cursor(null);
        }

        private Gdk.Cursor resize_cursor = null;
        private Gdk.Cursor? get_resize_cursor() {
            if (resize_cursor == null && this.get_realized()) {
                resize_cursor = new Gdk.Cursor.for_display(
                    this.get_window().get_display(),
                    Gdk.CursorType.BOTTOM_RIGHT_CORNER
                );
            }
            return resize_cursor;
        }

        public override bool motion_notify_event(Gdk.EventMotion e) {
            if (!this.editable)
                return false;
            // Check if we are on a node. If yes, check if we are
            // currently pointing on a dock. if this is true, we
            // Want to draw a new connector instead of dragging the node
            Node? n = this.get_node_on_position(e.x, e.y);
            GFlow.Dock? targeted_dock = null;
            if (n != null) {
                Gdk.Point pos = {(int)e.x, (int)e.y};
                Gtk.Allocation alloc;
                n.get_node_allocation(out alloc);
                bool cbp = n.node_renderer.is_on_closebutton(
                    pos, alloc,
                    (int)this.hadjustment.value,
                    (int)this.vadjustment.value,
                    n.border_width
                );
                if (!cbp)
                    this.close_button_pressed = false;
                // Update cursor if we are on the resize area
                bool on_resize = n.node_renderer.is_on_resize_handle(
                    pos, alloc,
                    (int)this.hadjustment.value,
                    (int)this.vadjustment.value,
                    n.border_width
                );
                if (on_resize)
                    this.get_window().set_cursor(this.get_resize_cursor());
                else if (this.resize_node == null)
                    this.get_window().set_cursor(null);
                targeted_dock = n.node_renderer.get_dock_on_position(
                    pos, n.get_dock_renderers(),
                    (int)this.hadjustment.value,
                    (int)this.vadjustment.value,
                    n.border_width, alloc
                );
                if (this.drag_dock == null && targeted_dock != this.hovered_dock) {
                    this.set_hovered_dock(targeted_dock);
                }
                else if (this.drag_dock != null && targeted_dock != null
                      && targeted_dock != this.hovered_dock
                      && this.is_suitable_target(this.drag_dock, targeted_dock)) {
                    this.set_hovered_dock(targeted_dock);
                }
            } else {
                // If we are leaving the node we will also have to
                // un-highlight the last hovered dock
                if (this.hovered_dock != null)
                    this.hovered_dock.highlight = false;
                this.hovered_dock = null;
                this.queue_draw();
                // Update cursor to be default as we are guaranteed not on any
                // resize handle outside of any node.
                // The check for resize node is a cosmetical fix. If there is a
                // Node bing resized in haste, the cursor tends to flicker
                if (this.resize_node == null)
                    this.get_window().set_cursor(null);
            }

            // Check if the cursor has been dragged a few pixels (defined by DRAG_THRESHOLD)
            // If yes, actually start dragging
            if ( ( this.drag_node != null || this.drag_dock != null || this.resize_node != null)
                    && (Math.fabs(drag_start_x - e.x) > NodeView.DRAG_THRESHOLD
                    ||  Math.fabs(drag_start_y - e.y) > NodeView.DRAG_THRESHOLD )) {
                this.drag_threshold_fulfilled = true;
            }

            // Actually something
            if (this.drag_threshold_fulfilled ) {
                if (this.drag_node != null) {
                    // Actually move the node
                    Gtk.Allocation alloc;
                    this.drag_node.get_node_allocation(out alloc);
                    alloc.x = (int)e.x - this.drag_diff_x;
                    alloc.y = (int)e.y - this.drag_diff_y;
                    this.drag_node.set_node_allocation(alloc);
                    this.recalculate_size();
                    this.queue_draw();
                }
                if (this.drag_dock != null) {
                    // Manipulate the temporary connector
                    this.temp_connector.width = (int)e.x-this.temp_connector.x;
                    this.temp_connector.height = (int)e.y-this.temp_connector.y;
                    if (targeted_dock == null) {
                        this.set_drop_dock(null);
                    }
                    else if (this.is_suitable_target(this.drag_dock, targeted_dock))
                        this.set_drop_dock(targeted_dock);

                    this.queue_draw();
                }
                if (this.resize_node != null) {
                    // resize the node
                    Gtk.Allocation alloc;
                    this.resize_node.get_node_allocation(out alloc);
                    alloc.width =  resize_start_x + (int)e.x - (int)this.drag_start_x;
                    alloc.height = resize_start_y + (int)e.y - (int)this.drag_start_y;
                    this.resize_node.set_node_allocation(alloc);
                    this.queue_draw();
                }
            }
            return false;
        }

        private void recalculate_size() {
            double x_min = 0, x_max = 0, y_min = 0, y_max = 0;
            Gtk.Allocation alloc;
            foreach (Node n in this.nodes) {
                n.get_node_allocation(out alloc);
                x_min = Math.fmin(x_min, alloc.x);
                x_max = Math.fmax(x_max, alloc.x+alloc.width);
                y_min = Math.fmin(y_min, alloc.y);
                y_max = Math.fmax(y_max, alloc.y+alloc.height);
            }
            this.hadjustment.lower = x_min;
            this.hadjustment.upper = x_max;
            this.vadjustment.lower = y_min;
            this.vadjustment.upper = y_max;
        }

        /**
         * Determines wheter one dock can be dropped on another
         */
        private bool is_suitable_target (GFlow.Dock from, GFlow.Dock to) {
            // Check whether the docks have the same type
            if (!from.has_same_type(to))
                return false;
            // Check if the target would lead to a recursion
            if (   from.node.is_recursive(to.node)
                || to.node.is_recursive(from.node))
                return false;
            // If the from from-target is a sink, check if the
            // to target is either a source which does not belong to the own node
            // or if the to target is another sink (this is valid as we can
            // move a connection from one sink to another
            if (from is GFlow.Sink
                    && ((to is GFlow.Sink
                    && to != from)
                    || (to is GFlow.Source
                    && !to.node.has_dock(from)))) {
                return true;
            }
            // Check if the from-target is a source. if yes, make sure the
            // to-target is a sink and it does not belong to the own node
            else if (from is GFlow.Source
                    && to is GFlow.Sink
                    && !to.node.has_dock(from)) {
                return true;
            }
            return false;
        }

        /**
         * Sets the dock that is currently being hovered over to drop
         * a connector on
         */
        private void set_drop_dock(GFlow.Dock? d) {
            if (this.drop_dock != null)
                this.drop_dock.active = false;
            this.drop_dock = d;
            if (this.drop_dock != null)
                this.drop_dock.active = true;
            this.queue_draw();
        }

        /**
         * Sets the dock that is currently being hovered over
         */
        private void set_hovered_dock(GFlow.Dock? d) {
            if (this.hovered_dock != null)
                this.hovered_dock.highlight = false;
            this.hovered_dock = d;
            if (this.hovered_dock != null)
                this.hovered_dock.highlight = true;
            this.queue_draw();
        }

        /**
         * Manually set the position of the given node on this nodeview
         */
        public void set_node_position(GFlow.Node gn, int x, int y) {
            Node n = this.get_node_from_gflow_node(gn);
            n.set_position(x,y);
        }

        public override bool draw(Cairo.Context cr) {
            Gtk.StyleContext sc = this.get_style_context();
            Gdk.RGBA bg = sc.get_background_color(Gtk.StateFlags.NORMAL);
            cr.set_source_rgba(bg.red, bg.green, bg.blue, bg.alpha);
            cr.paint();
            // Draw nodes
            this.nodes.reverse();
            foreach (Node n in this.nodes) {
                Gtk.Allocation alloc;
                n.get_node_allocation(out alloc);
                n.node_renderer.draw_node(
                    cr,
                    n.get_style_context(),
                    alloc,
                    n.get_dock_renderers(),
                    n.get_children(),
                    (int)this.hadjustment.value,
                    (int)this.vadjustment.value,
                    (int)n.border_width,
                    this.editable
                );
            }
            this.nodes.reverse();
            // Draw connectors
            foreach (Node n in this.nodes) {
                foreach(GFlow.Source source in n.gnode.get_sources()) {
                    Gtk.Allocation alloc;
                    n.get_node_allocation(out alloc);
                    int source_pos_x = 0, source_pos_y = 0;
                    if (!n.node_renderer.get_dock_position(
                            source,
                            n.get_dock_renderers(),
                            (int)this.hadjustment.value,
                            (int)this.vadjustment.value,
                            (int)n.border_width,
                            alloc, out source_pos_x, out source_pos_y)) {
                        warning("No dock on position. Ommiting connector");
                        continue;
                    }
                    Gdk.Point source_pos = {source_pos_x,source_pos_y};
                    foreach(GFlow.Sink sink in source.sinks) {
                        // Don't draw the connection to a sink if we are dragging it
                        if (sink == this.drag_dock)
                            continue;
                        Node? sink_node = this.get_node_from_gflow_node(sink.node);
                        sink_node.get_node_allocation(out alloc);
                        int sink_pos_x = 0, sink_pos_y = 0;
                        if (!sink_node.node_renderer.get_dock_position(
                                sink,
                                sink_node.get_dock_renderers(),
                                (int)this.hadjustment.value,
                                (int)this.vadjustment.value,
                                (int)sink_node.border_width,
                                alloc, out sink_pos_x, out sink_pos_y )) {
                            warning("No dock on position. Ommiting connector");
                            continue;
                        }
                        Gdk.Point sink_pos = {sink_pos_x,sink_pos_y};
                        int w = sink_pos.x - source_pos.x;
                        int h = sink_pos.y - source_pos.y;
                        cr.move_to(source_pos.x, source_pos.y);
                        cr.rel_curve_to(w,0,0,h,w,h);
                        cr.stroke();
                    }
                }
            }
            // Draw temporary connector if any
            if (this.temp_connector != null) {
                int w = this.temp_connector.width;
                int h = this.temp_connector.height;
                cr.move_to(this.temp_connector.x, this.temp_connector.y);
                cr.rel_curve_to(w,0,0,h,w,h);
                cr.stroke();
            }
            return true;
        }

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
                 | Gdk.EventMask.BUTTON_RELEASE_MASK
                 | Gdk.EventMask.LEAVE_NOTIFY_MASK;
            Gdk.WindowAttributesType mask = Gdk.WindowAttributesType.X 
                 | Gdk.WindowAttributesType.X 
                 | Gdk.WindowAttributesType.VISUAL;
            var window = new Gdk.Window(this.get_parent_window(), attr, mask);
            this.set_window(window);
            this.register_window(window);
            this.set_realized(true);
            window.set_background_pattern(null);
        }
    }
}
