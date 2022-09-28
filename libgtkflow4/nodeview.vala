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
    private errordomain InternalError {
        DOCKS_NOT_SUITABLE
    }

    public interface NodeRenderer : Gtk.Widget {
        public abstract GFlow.Node n {get; protected set;}
        public abstract bool marked {get; internal set;}
        public abstract Dock? retrieve_dock(GFlow.Dock d);
    }

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

    public class Node : Gtk.Widget, NodeRenderer  {
        construct {
            set_css_name("gtkflow_node");
        }

        private Gtk.GestureClick ctr_click;
        public GFlow.Node n {get; protected set;}

        public bool marked {get; internal set;}
        public bool resizable {get; set; default=true;}

        public Gtk.Widget title_widget {get; set;}
        private Gtk.Label title_label;
        private Gtk.Button delete_button;

        public double click_offset_x {get; private set; default=0;}
        public double click_offset_y {get; private set; default=0;}
        public double resize_start_width {get; private set; default=0;}
        public double resize_start_height {get; private set; default=0;}

        private HashTable<GFlow.Dock, Gtk.Widget> widgets;

        private int n_docks = 0;

        public Node(GFlow.Node n) {
            this.n = n;

            var grid = new Gtk.GridLayout();
            grid.column_homogeneous = false;
            grid.column_spacing = 5;
            grid.row_homogeneous = false;
            grid.row_spacing = 5;
            this.set_layout_manager(grid);

            this.ctr_click = new Gtk.GestureClick();
            this.add_controller(this.ctr_click);
            this.ctr_click.pressed.connect((n, x, y) => { this.press_button(n,x,y); });
            this.ctr_click.end.connect(() => { this.release_button(); });

            this.title_label = new Gtk.Label(n.name);
            this.title_label.set_parent(this);
            var title_label_lc = (Gtk.GridLayoutChild) grid.get_layout_child(this.title_label);
            title_label_lc.row = 0;
            title_label_lc.row_span = 1;
            title_label_lc.column = 0;
            title_label_lc.column_span = 2;

            var delete_icon = new Gtk.Image.from_icon_name("edit-delete");
            this.delete_button = new Gtk.Button();
            this.delete_button.child = delete_icon;
            this.delete_button.set_parent(this);
            this.delete_button.clicked.connect(this.cb_delete);
            var delete_button_lc = (Gtk.GridLayoutChild) grid.get_layout_child(this.delete_button);
            delete_button_lc.row = 0;
            delete_button_lc.row_span = 1;
            delete_button_lc.column = 2;
            delete_button_lc.column_span = 1;

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
            var c = this.get_first_child();
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

        private void cb_delete() {
            var nv = this.get_parent() as NodeView;
            nv.remove(this);
        }

        public void add_child(Gtk.Widget child) {
            child.set_parent(this);
            child.margin_top = 10;
            child.margin_bottom = 10;
            child.margin_start = 10;
            child.margin_end = 10;
            var grid = (Gtk.GridLayout) this.layout_manager;
            var lc = (Gtk.GridLayoutChild)grid.get_layout_child(child);
            lc.row = 2 + n_docks;
            lc.row_span = 1;
            lc.column = 0;
            lc.column_span = 3;
        }

        public void remove_child(Gtk.Widget child) {
            child.unparent();
        }

        private void sink_added(GFlow.Sink s) {
            var radio = new Dock(s);
            var label = new Gtk.Label(s.name);
            var grid = (Gtk.GridLayout) this.layout_manager;
            radio.set_parent(this);
            label.set_parent(this);

            var radio_lc = (Gtk.GridLayoutChild)grid.get_layout_child(radio);
            radio_lc.row = 1 + ++n_docks;
            radio_lc.row_span = 1;
            radio_lc.column = 0;
            radio_lc.column_span = 1;

            var label_lc = (Gtk.GridLayoutChild)grid.get_layout_child(label);
            label_lc.row = 1 + n_docks;
            label_lc.row_span = 1;
            label_lc.column = 1;
            label_lc.column_span = 1;
        }

        private void source_added(GFlow.Source s) {
            var radio = new Dock(s);
            var label = new Gtk.Label(s.name);
            var grid = (Gtk.GridLayout) this.layout_manager;
            radio.set_parent(this);
            label.set_parent(this);

            var radio_lc = (Gtk.GridLayoutChild) grid.get_layout_child(radio);
            radio_lc.row = 1 + ++n_docks;
            radio_lc.row_span = 1;
            radio_lc.column = 2;
            radio_lc.column_span = 1;

            var label_lc = (Gtk.GridLayoutChild)grid.get_layout_child(label);
            label_lc.row = 1 + n_docks;
            label_lc.row_span = 1;
            label_lc.column = 1;
            label_lc.column_span = 1;
        }

        private void press_button(int n_click, double x, double y) {
            var picked_widget = this.pick(x,y, Gtk.PickFlags.NON_TARGETABLE);

            bool do_processing = false;
            if (picked_widget == this) {
                do_processing = true;
            } else if (picked_widget.get_parent() == this) {
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
            } else {
                color = {0.5f,0.5f,0.5f,0.8f};
                grey_color = {0.6f,0.6f,0.6f,0.5f};
            }
            Gdk.RGBA[] border_color = {color,color,color,color};
            float[] thicc = {1f,1f,1f,1f};
            sn.append_color(grey_color ,rect );
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

        protected override  void measure(Gtk.Orientation o, int for_size, out int min, out int pref, out int min_base, out int pref_base) {
            message("lol %d", for_size);
            min = 200;
            pref = 100;
            min_base = -1;
            pref_base = -1;
        }

        /*protected override void size_allocate(int height, int width, int baseline) {
            message("LELL");
        }*/

    }

    private class NodeViewLayoutManager : Gtk.LayoutManager {
        protected override Gtk.SizeRequestMode get_request_mode (Gtk.Widget widget) {
            return Gtk.SizeRequestMode.CONSTANT_SIZE;
        }

        protected override  void measure(Gtk.Widget w, Gtk.Orientation o, int for_size, out int min, out int pref, out int min_base, out int pref_base) {
            int lower_bound = 0;
            int upper_bound = 0;
            var c = w.get_first_child();
            while (c != null) {
                var lc = (NodeViewLayoutChild)this.get_layout_child(c);
                switch (o) {
                    case Gtk.Orientation.HORIZONTAL:
                        if (lc.x < 0) {
                            lower_bound = int.min(lc.x, lower_bound);
                        } else {
                            upper_bound = int.max(lc.x + c.get_width(), upper_bound);
                        }
                        break;
                    case Gtk.Orientation.VERTICAL:
                        if (lc.y < 0) {
                            lower_bound = int.min(lc.y, lower_bound);
                        } else {
                            upper_bound = int.max(lc.y + c.get_height(), upper_bound);
                        }
                        break;
                }

                c = c.get_next_sibling();
            }
            min = upper_bound - lower_bound;
            pref = upper_bound - lower_bound;
            min_base = -1;
            pref_base = -1;
        }

        protected override void allocate(Gtk.Widget w, int height, int width, int baseline) {
            var c = w.get_first_child();
            while (c != null) {
                int cwidth, cheight, _;
                c.measure(Gtk.Orientation.HORIZONTAL, -1, out cwidth, out _, out _, out _);
                c.measure(Gtk.Orientation.VERTICAL, -1, out cheight, out _, out _, out _);
                var lc = (NodeViewLayoutChild)this.get_layout_child(c);
                c.queue_allocate();
                c.allocate_size({lc.x,lc.y, cwidth, cheight}, -1);
                c = c.get_next_sibling();
            }
        }
        public override Gtk.LayoutChild create_layout_child (Gtk.Widget widget, Gtk.Widget for_child)  {
            return new NodeViewLayoutChild(for_child, this);
        }
    }

    private class NodeViewLayoutChild : Gtk.LayoutChild {
        public int x = 0;
        public int y = 0;

        public NodeViewLayoutChild(Gtk.Widget w, Gtk.LayoutManager lm) {
            Object(child_widget: w, layout_manager: lm);
        }
    }

    public class NodeView : Gtk.Widget {
        construct {
            set_css_name("gtkflow_nodeview");
        }

        /**
         * If this property is set to true, the nodeview will not perform
         * any check wheter newly created connections will result in cycles
         * in the graph. It's completely up to the application programmer
         * to make sure that the logic inside the nodes he uses avoids
         * endlessly backpropagated loops
         */
        public bool allow_recursion {get; set; default=false;}

        /**
         * The eventcontrollers to receive events
         */
        private Gtk.EventControllerMotion ctr_motion;
        private Gtk.GestureClick ctr_click;
        /**
         * The current extents of the temporary connector
         * if null, there is no temporary connector drawn at the moment
         */
        private Gdk.Rectangle? temp_connector = null;

        /**
         * The dock that the temporary connector will be attched to
         */
        private Dock? temp_connected_dock = null;
        /**
         * The dock that was clicked to invoke the temporary connector
         */
        private Dock? clicked_dock = null;
        /**
         * The node that is being moved right now via mouse drag.
         * The node that receives the button press event registers
         * itself with this property
         */
        internal Node? move_node {get; set; default=null;}
        internal Node? resize_node {get; set; default=null;}

        /**
         * A rectangle detailing the extents of a rubber marking
         */
        private Gdk.Rectangle? mark_rubberband = null;

        public NodeView (){
            this.set_layout_manager(new NodeViewLayoutManager());
            this.set_size_request(100,100);

            this.ctr_motion = new Gtk.EventControllerMotion();
            this.add_controller(this.ctr_motion);
            this.ctr_motion.motion.connect((x,y)=> { this.process_motion(x,y); });

            this.ctr_click = new Gtk.GestureClick();
            this.add_controller(this.ctr_click);
            this.ctr_click.pressed.connect((n,x,y) => { this.start_marking(n,x,y); });
            this.ctr_click.released.connect((n,x,y) => { this.end_temp_connector(n,x,y); });
        }

        private List<unowned NodeRenderer> get_marked_nodes() {
            var result = new List<unowned NodeRenderer>();
            var nodewidget = this.get_first_child();
            while (nodewidget != null) {
                var node = (NodeRenderer)nodewidget;
                if (node.marked) {
                    result.append(node);
                }
                nodewidget = nodewidget.get_next_sibling();
            }
            return result;
        }

        private void process_motion(double x, double y) {
            if (this.move_node != null) {
                var lc = (NodeViewLayoutChild) this.layout_manager.get_layout_child(this.move_node);
                int old_x = lc.x;
                int old_y = lc.y;
                lc.x = (int)(x-this.move_node.click_offset_x);
                lc.y = (int)(y-this.move_node.click_offset_y);
                if (this.move_node.marked) {
                    int diff_x, diff_y;
                    foreach (NodeRenderer n in this.get_marked_nodes()) {
                        if (n == this.move_node) continue;
                        var mlc = (NodeViewLayoutChild) this.layout_manager.get_layout_child(n);
                        diff_x = old_x - lc.x;
                        diff_y = old_y - lc.y;
                        mlc.x -= diff_x;
                        mlc.y -= diff_y;
                    }
                }
            }

            if (this.resize_node != null) {
                int d_x, d_y;
                Gtk.Allocation node_alloc;
                this.resize_node.get_allocation(out node_alloc);
                d_x = (int)(x-this.resize_node.click_offset_x-node_alloc.x);
                d_y = (int)(y-this.resize_node.click_offset_y-node_alloc.y);
                int new_width = (int)this.resize_node.resize_start_width+d_x;
                int new_height = (int)this.resize_node.resize_start_height+d_y;
                this.resize_node.set_size_request(new_width, new_height);
                message("resze %d %d", new_width, new_height);
            }

            if (this.temp_connector != null) {
                this.temp_connector.width = (int)(x - this.temp_connector.x);
                this.temp_connector.height = (int)(y - this.temp_connector.y);
            }

            if (this.mark_rubberband != null) {
                this.mark_rubberband.width = (int)(x - this.mark_rubberband.x);
                this.mark_rubberband.height = (int)(y - this.mark_rubberband.y);
                var nodewidget = this.get_first_child();
                Gtk.Allocation node_alloc;
                Gdk.Rectangle absolute_marked = this.mark_rubberband;
                if (absolute_marked.width < 0) {
                    absolute_marked.width *= -1;
                    absolute_marked.x -= absolute_marked.width;
                }
                if (absolute_marked.height < 0) {
                    absolute_marked.height *= -1;
                    absolute_marked.y -= absolute_marked.height;
                }
                Gdk.Rectangle result;
                while (nodewidget != null) {
                    var node = (NodeRenderer)nodewidget;
                    node.get_allocation(out node_alloc);
                    node_alloc.intersect(absolute_marked, out result);
                    node.marked = result == node_alloc;
                    nodewidget = node.get_next_sibling();
                }
            }

            this.queue_allocate();
        }


        private void start_marking(int n_clicks, double x, double y) {
            if (this.pick(x,y, Gtk.PickFlags.DEFAULT) == this)
                this.mark_rubberband = {(int)x,(int)y,0,0};
        }

        internal void start_temp_connector(Dock d) {
            this.clicked_dock = d;
            if (d.d is GFlow.Sink && d.d.is_linked()) {
                var sink = (GFlow.Sink)d.d;
                this.temp_connected_dock = this.retrieve_dock(sink.sources.last().nth_data(0));
            } else {
                this.temp_connected_dock = d;
            }
            var node = this.retrieve_node(this.temp_connected_dock.d.node);

            Gtk.Allocation node_alloc, dock_alloc;
            node.get_allocation(out node_alloc);
            this.temp_connected_dock.get_allocation(out dock_alloc);
            var x = node_alloc.x + dock_alloc.x + 8;
            var y = node_alloc.y + dock_alloc.y + 8;
            this.temp_connector = {x, y, 0, 0};
        }

        internal void end_temp_connector(int n_clicks, double x, double y) {
            if (this.temp_connector != null) {
                var w = this.pick(x,y,Gtk.PickFlags.DEFAULT);
                if (w is Dock) {
                    var pd = (Dock)w;
                    if (pd.d is GFlow.Source && this.temp_connected_dock.d is GFlow.Sink
                     || pd.d is GFlow.Sink && this.temp_connected_dock.d is GFlow.Source) {
                        try {
                            if (!this.is_suitable_target(pd.d, this.temp_connected_dock.d)) {
                                throw new InternalError.DOCKS_NOT_SUITABLE("Can't link because is no good");
                            }
                            pd.d.link(this.temp_connected_dock.d);
                        } catch (Error e) {
                            warning("Could not link: "+e.message);
                        }
                    }
                    else if (pd.d is GFlow.Sink && this.clicked_dock != null
                      && this.clicked_dock.d is GFlow.Sink
                      && this.temp_connected_dock is GFlow.Source) {
                        try {
                            if (!this.is_suitable_target(pd.d, this.temp_connected_dock.d)) {
                                throw new InternalError.DOCKS_NOT_SUITABLE("Can't link because is no good");
                            }
                            this.clicked_dock.d.unlink(this.temp_connected_dock.d);
                            pd.d.link(this.temp_connected_dock.d);
                        } catch (Error e) {
                            warning("Could not edit links: "+e.message);
                        }

                    }
                    pd.queue_draw();
                } else {
                    if (this.temp_connected_dock.d is GFlow.Source
                     && this.clicked_dock != null
                     && this.clicked_dock.d is GFlow.Sink) {
                        try {
                            this.clicked_dock.d.unlink(this.temp_connected_dock.d);
                        } catch (Error e) {
                            warning("Could not unlink: "+e.message);
                        }
                     }
                }

                this.queue_draw();
                this.temp_connected_dock.queue_draw();
                if (this.clicked_dock != null) {
                    this.clicked_dock.queue_draw();
                }
                this.clicked_dock = null;
                this.temp_connected_dock = null;
                this.temp_connector = null;

            }

            this.mark_rubberband = null;
            this.queue_allocate();
        }

        public void add(Node n) {
            n.set_parent (this);
        }

        public void remove(Node n) {
            n.n.unlink_all();
            var child = this.get_first_child ();
            while (child != null) {
                if (child == n) {
                    // TODO: find out why destroy wont work as intended
                    child.destroy ();
                    child.hide();
                    return;
                }
                child = child.get_next_sibling();
            }
            warning("Tried to remove a node that is not a child of nodeview");
        }

        /**
         * Retrieve a Node-Widget from this node.
         *
         * Gives you the GtkFlow.Node-object that corresponds to the given
         * GFlow.Node. Returns null if the searched Node is not associated
         * with any of the Node-Widgets in this node.
         */
        public NodeRenderer? retrieve_node (GFlow.Node n) {
            var c = (NodeRenderer)this.get_first_child();
            while (c != null) {
                if (!(c is NodeRenderer )) continue;
                if (c.n == n) return c;
                c = (NodeRenderer)c.get_next_sibling();
            }
            return null;
        }

        internal Dock? retrieve_dock (GFlow.Dock d) {
            var c = (NodeRenderer)this.get_first_child();
            Dock? found = null;
            while (c != null) {
                if (!(c is NodeRenderer )) {
                    c = (NodeRenderer)c.get_next_sibling();
                    continue;
                }
                found = c.retrieve_dock(d);
                if (found != null) return found;
                c = (NodeRenderer)c.get_next_sibling();
            }
            return null;
        }

        /**
         * Determines wheter one dock can be dropped on another
         */
        private bool is_suitable_target (GFlow.Dock from, GFlow.Dock to) {
            // Check whether the docks have the same type
            if (!from.has_same_type(to))
                return false;
            // Check if the target would lead to a recursion
            // If yes, return the value of allow_recursion. If this
            // value is set to true, it's completely fine to have
            // a recursive graph
            if (to is GFlow.Source && from is GFlow.Sink) {
                if (!this.allow_recursion)
                    if (from.node.is_recursive_forward(to.node) ||
                           to.node.is_recursive_backward(from.node))
                        return false;
            }
            if (to is GFlow.Sink && from is GFlow.Source) {
                if (!this.allow_recursion)
                    if (to.node.is_recursive_forward(from.node) ||
                           from.node.is_recursive_backward(to.node))
                        return false;
            }
            if (to is GFlow.Sink && from is GFlow.Sink) {
                GFlow.Source? s = ((GFlow.Sink)from).sources.last().nth_data(0);
                if (s == null)
                    return false;
                if (!this.allow_recursion)
                    if (to.node.is_recursive_forward(s.node) ||
                           s.node.is_recursive_backward(to.node))
                        return false;
            }
            // If the from from-target is a sink, check if the
            // to target is either a source which does not belong to the own node
            // or if the to target is another sink (this is valid as we can
            // move a connection from one sink to another
            if (from is GFlow.Sink
                    && ((to is GFlow.Sink
                    && to != from)
                    || (to is GFlow.Source
                    && (!to.node.has_dock(from) || this.allow_recursion)))) {
                return true;
            }
            // Check if the from-target is a source. if yes, make sure the
            // to-target is a sink and it does not belong to the own node
            else if (from is GFlow.Source
                    && to is GFlow.Sink
                    && (!to.node.has_dock(from) || this.allow_recursion)) {
                return true;
            }
            return false;
        }

        protected override void snapshot (Gtk.Snapshot sn) {
            base.snapshot(sn);
            var rect = Graphene.Rect().init(0,0,(float)this.get_width(), (float)this.get_height());
            var cr = sn.append_cairo(rect);

            Gdk.RGBA color = {0.0f,0.0f,0.0f,1.0f};

            var c = this.get_first_child();
            while (c != null) {
                var nr = (NodeRenderer)c;
                int tgt_x, tgt_y, src_x, src_y, w, h;
                foreach (GFlow.Sink snk in nr.n.get_sinks()) {
                    var target_widget = this.retrieve_dock(snk);
                    Gtk.Allocation tgt_alloc, tgt_node_alloc;
                    target_widget.get_allocation(out tgt_alloc);
                    nr.get_allocation(out tgt_node_alloc);
                    foreach (GFlow.Source src in snk.sources) {
                        if (this.temp_connected_dock != null && src == this.temp_connected_dock.d
                         && this.clicked_dock != null && snk == this.clicked_dock.d) {
                            continue;
                        }
                        var source_widget = this.retrieve_dock(src);
                        var source_node = this.retrieve_node(src.node);
                        Gtk.Allocation src_alloc, src_node_alloc;
                        source_widget.get_allocation(out src_alloc);
                        source_node.get_allocation(out src_node_alloc);

                        src_x = src_alloc.x+src_node_alloc.x+8;
                        src_y = src_alloc.y+src_node_alloc.y+8;
                        tgt_x = tgt_alloc.x+tgt_node_alloc.x+8;
                        tgt_y = tgt_alloc.y+tgt_node_alloc.y+8;
                        w = tgt_x - src_x;
                        h = tgt_y - src_y;

                        cr.save();
                        cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
                        cr.move_to(src_x, src_y);
                        if (w > 0) {
                            cr.rel_curve_to(w/3,0,2*w/3,h,w,h);
                        } else {
                            cr.rel_curve_to(-w/3,0,1.3*w,h,w,h);
                        }
                        cr.stroke();
                        cr.restore();
                    }
                }
                c = c.get_next_sibling();
            }
            if (this.temp_connector != null) {
                cr.save();
                cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
                cr.move_to(this.temp_connector.x, this.temp_connector.y);
                cr.rel_curve_to(
                    this.temp_connector.width/3,
                    0,
                    2*this.temp_connector.width/3,
                    this.temp_connector.height,
                    this.temp_connector.width,
                    this.temp_connector.height
                );
                cr.stroke();
                cr.restore();
            }
            if (this.mark_rubberband != null) {
                cr.save();
                cr.set_source_rgba(0.0, 0.2, 0.9, 0.4);
                cr.rectangle(
                    this.mark_rubberband.x, this.mark_rubberband.y,
                    this.mark_rubberband.width, this.mark_rubberband.height
                );
                cr.fill();
                cr.set_source_rgba(0.0, 0.2, 1.0, 1.0);
                cr.stroke();
            }
        }
    }
}

