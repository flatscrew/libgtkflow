namespace GtkFlow {
    public interface NodeRenderer : Gtk.Widget {
    }

    private class Dock : Gtk.Widget {
        construct {
            set_css_name("gtkflow_dock");
        }

        public Dock() {
            this.valign = Gtk.Align.CENTER;
            this.halign = Gtk.Align.CENTER;
            this.margin_start = 8;
            this.margin_end = 8;
            this.margin_top = 4;
            this.margin_bottom = 4;
        }

        protected override void snapshot (Gtk.Snapshot sn) {
            message("drawing node");
            var rect = Graphene.Rect().init(0,0,16, 16);
            var rrect = Gsk.RoundedRect().init_from_rect(rect, 8f);
            Gdk.RGBA color = {0.9f,0.9f,0.9f,1.0f};
            Gdk.RGBA grey_color = {0.6f,0.6f,0.6f,1.0f};
            Gdk.RGBA[] border_color = {color,color,color,color};
            float[] thicc = {1f,1f,1f,1f};
            sn.append_border(rrect, thicc, border_color);
            sn.append_inset_shadow(rrect, grey_color, 2f, 2f, 3f, 3f);
            base.snapshot(sn);
        }

        protected override  void measure(Gtk.Orientation o, int for_size, out int min, out int pref, out int min_base, out int pref_base) {
            message("measure dock %d", for_size);
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
        private GFlow.Node n;

        public Gtk.Widget title_widget {get; set;}
        private Gtk.Label title_label;
        private Gtk.Button delete_button;

        public double click_offset_x {get; private set; default=0;}
        public double click_offset_y {get; private set; default=0;}

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

        private void sink_added(GFlow.Sink s) {
            var radio = new Dock();
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
            var radio = new Dock();
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

            var nv = this.get_parent() as NodeView;
            this.click_offset_x = x;
            this.click_offset_y = y;
            nv.move_node = this;
        }

        private void release_button() {
            var nv = this.get_parent() as NodeView;
            nv.move_node = null;
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
            //message("drawing node");
            var rect = Graphene.Rect().init(0,0,this.get_width(), this.get_height());
            var rrect = Gsk.RoundedRect().init_from_rect(rect, 5f);
            Gdk.RGBA color = {0.6f,1.0f,0.0f,1.0f};
            Gdk.RGBA grey_color = {0.6f,0.6f,0.6f,0.5f};
            Gdk.RGBA[] border_color = {color,color,color,color};
            float[] thicc = {1f,1f,1f,1f};
            sn.append_color(grey_color ,rect );
            sn.append_border(rrect, thicc, border_color);
            sn.append_outset_shadow(rrect, grey_color, 2f, 2f, 3f, 3f);
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
            message("nvl reqmode");
            return Gtk.SizeRequestMode.CONSTANT_SIZE; 
        }

        protected override  void measure(Gtk.Widget w, Gtk.Orientation o, int for_size, out int min, out int pref, out int min_base, out int pref_base) {
            message("nvl measure");
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

        private Gtk.EventControllerMotion ctr_motion;
        internal Node? move_node {get; set; default=null;}

        public NodeView (){
            this.set_layout_manager(new NodeViewLayoutManager());
            this.set_size_request(100,100);

            this.ctr_motion = new Gtk.EventControllerMotion();
            this.add_controller(this.ctr_motion);
            this.ctr_motion.motion.connect((x,y)=> { this.process_motion(x,y); });
        }

        private void process_motion(double x, double y) {
            if (this.move_node == null) {
                return;
            }

            var lc = (NodeViewLayoutChild) this.layout_manager.get_layout_child(this.move_node);
            lc.x = (int)(x-this.move_node.click_offset_x);
            lc.y = (int)(y-this.move_node.click_offset_y);

            this.queue_allocate();
        }

        public void add(Node n) {
            n.set_parent (this);
        }

        public void remove(Node n) {
            var child = this.get_first_child ();
            while (child != null) {
                if (child == n) {
                    child.unparent ();
                    return;
                }
                child = this.get_first_child ();
            }
            warning("Tried to remove a node that is not a child of nodeview");
        }

        protected override void snapshot (Gtk.Snapshot sn) {
            //message("drawing");
            //var cr = sn.append_cairo();
            Gdk.RGBA color = {0.6f,1.0f,0.0f,1.0f};
            var rect = Graphene.Rect().init(0,0,(float)(this.get_width()/2.0), (float)(this.get_height()/2.0));
            sn.append_color(color, rect);
            
            base.snapshot(sn);
        }

    }
}

