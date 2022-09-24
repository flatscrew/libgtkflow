namespace GtkFlow {
    public class Node : Gtk.Widget  {
        construct {
            set_css_name("gtkflow_node");
        }

        private Gtk.GestureClick ctr_click;
        private Gtk.EventControllerMotion ctr_motion;
        private GFlow.Node n;

        private bool button_pressed = false;
        private double x_offset = 0;
        private double y_offset = 0;

        public Node(GFlow.Node n) {
            this.n = n;
            this.ctr_click = new Gtk.GestureClick();
            this.add_controller(this.ctr_click);
            this.ctr_click.pressed.connect((n, x, y) => { this.press_button(n,x,y); });   
            this.ctr_click.released.connect((n, x, y) => { this.release_button(n,x,y); });

            this.ctr_motion = new Gtk.EventControllerMotion();
            this.add_controller(this.ctr_motion);
            this.ctr_motion.motion.connect((x,y)=> { this.process_motion(x,y); });

        }

        private void press_button(int n_click, double x, double y) {
            message("cpress %u", this.ctr_click.get_current_button());
            x_offset = x;
            y_offset = y;
            this.button_pressed = true;
        }

        private void release_button(int n_click, double x, double y) {
            message("crelea %u", this.ctr_click.get_current_button());
            this.button_pressed = false;
        }

        private void process_motion(double x, double y) {
            if (!this.button_pressed) return;
            message("motio %f %f", x, y);
            if (!(this.get_parent() is NodeView)) {
                warning("Trying to move a node that is not in a NodeView!");
                return;
            }
            var nv = this.get_parent() as NodeView;
            var lc = (Gtk.FixedLayoutChild) nv.get_layout_manager().get_layout_child(this);
            float dx, dy;
            lc.transform.to_translate(out dx, out dy);
            message("pos %f %f",dx,dy);
            var transform = lc.transform.translate(Graphene.Point().init((float)(x-x_offset), (float)(y-y_offset)));
            lc.set_transform(transform);
        }

        protected override void snapshot (Gtk.Snapshot sn) {
            message("drawing node");
            var rect = Graphene.Rect().init(0,0,this.get_width(), this.get_height());
            var rrect = Gsk.RoundedRect().init_from_rect(rect, 5f);
            Gdk.RGBA color = {0.6f,1.0f,0.0f,1.0f};
            Gdk.RGBA grey_color = {0.6f,0.6f,0.6f,0.5f};
            Gdk.RGBA[] border_color = {color,color,color,color};
            float[] thicc = {1f,1f,1f,1f};
            sn.append_border(rrect, thicc, border_color);
            sn.append_outset_shadow(rrect, grey_color, 2f, 2f, 3f, 3f);
            
            /*var cr = sn.append_border();
            sn.appa*/
            
        }

        protected override  void measure(Gtk.Orientation o, int for_size, out int min, out int pref, out int min_base, out int pref_base) {
            message("lol %d", for_size);
            min = 50;
            pref = 100;
            min_base = -1;
            pref_base = -1;
        }

        protected override void size_allocate(int height, int width, int baseline) {
            message("LELL");
        }
        
    }

    private class NodeViewLayoutManager : Gtk.LayoutManager {
        protected override Gtk.SizeRequestMode get_request_mode (Gtk.Widget widget) {
            message("nvl reqmode");
            return Gtk.SizeRequestMode.CONSTANT_SIZE; 
        }

        protected override  void measure(Gtk.Widget w, Gtk.Orientation o, int for_size, out int min, out int pref, out int min_base, out int pref_base) {
            message("nvl measure");
            min = 50;
            pref = 100;
            min_base = -1;
            pref_base = -1;
        }

        protected override void allocate(Gtk.Widget w, int height, int width, int baseline) {
            message("nvl allocate");
            var c = w.get_first_child();
            int x, y = 0;
            while (c != null) {
                x += 10;
                y += 10;
                message("%d %d %d %d", x,y,c.get_width(), c.get_height());
                c.allocate_size({x,y, 50, 50}, -1);
                c = c.get_next_sibling();
            }
            message("LELL");
        }
    }

    public class NodeView : Gtk.Widget {
        // TODO: delte these
        private int x = 0;
        private int y = 0;
        construct {
            set_css_name("gtkflow_nodeview");
        }
        public NodeView (){
            this.set_layout_manager(new Gtk.FixedLayout());
            this.set_size_request(100,100);
            //this.queue_draw();
            message("wee %f %f",this.get_width(), this.get_height());
        }

        public void add(Node n) {
            n.set_parent (this);
            var cn = this.layout_manager.get_layout_child(n) as Gtk.FixedLayoutChild;
            x+=10;
            y+=10;
            message("got cn");
            var transform = cn.transform.translate(Graphene.Point().init(x,y));
            cn.set_transform(transform);
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
            base.snapshot(sn);
            message("drawing");
            //var cr = sn.append_cairo();
            Gdk.RGBA color = {0.6f,1.0f,0.0f,1.0f};
            var rect = Graphene.Rect().init(0,0,(float)(this.get_width()/2.0), (float)(this.get_height()/2.0));
            sn.append_color(color, rect);
            
        }

    }

    public class ClockFace : Gtk.Widget {
        GLib.TimeZone _time_zone;

        bool _ticking = false;
        uint _ticking_id = 0;

        GLib.DateTime _now;
        GLib.DateTime now {
            owned get {
                return new GLib.DateTime.now (_time_zone);
            }
            protected set {
                _now = value;
            }
        }

        public string time {
            owned get {
                return now.format ("%x\n%X");
            }
        }

        static construct {
            set_css_name ("clock");
        }

        public ClockFace (string ? time_zone = null) {
            set_time_zone (time_zone);
            start_ticking ();
        }

        public void set_time_zone (string ? timezone) {
            if (timezone == null) {
                this.now = new GLib.DateTime.now_utc ();
                try {
                    this._time_zone = new GLib.TimeZone.identifier ("UTC");
                } catch (GLib.Error err) {
                    GLib.error ("Gould not parse time zones: %s\n", err.message);
                }
            } else {
                try {
                    var zone = new GLib.TimeZone.identifier (timezone);
                    this.now = new GLib.DateTime.now (zone);
                    this._time_zone = zone;
                } catch (GLib.Error err) {
                    GLib.error ("Gould not parse time zones: %s\n", err.message);
                }
            }
            this.tick ();
        }

        /* Here, we implement the functionality required by the GdkPaintable
         * interface. This way we have a trivial way to display an analog clock.
         * It also allows demonstrating how to directly use objects in the
         * listview later by making this object do something interesting.
         */
        protected override void snapshot (Gtk.Snapshot snapshot) {
            Gsk.RoundedRect outline = {};

            var w = this.get_width ();
            var h = this.get_height ();

            var context = this.get_style_context ();
            var foreground_color = context.get_color ();

            /* save/restore() is necessary so we can undo the transforms we start
             * out with.
             */
            snapshot.save ();

            /* First, we move the (0, 0) point to the center of the area so
             * we can draw everything relative to it.
             */
            snapshot.translate ({ w / 2, h / 2 });

            /* Next we scale it, so that we can pretend that the clock is
             * 100px in size. That way, we don't need to do any complicated
             * math later. We use MIN() here so that we use the smaller
             * dimension for sizing. That way we don't overdraw but keep
             * the aspect ratio.
             */
            snapshot.scale (float.min (w, h) /
                            100.0f, float.min (w, h) / 100.0f);

            /* Now we have a circle with diameter 100px (and radius 50px) that
             * has its (0, 0) point at the center. Let's draw a simple clock into it.
             */


            /* First, draw a circle. This is a neat little trick to draw a circle
             * without requiring Cairo.
             */
            outline.init_from_rect ({ { -50, -50 }, { 100, 100 } }, 50f);
            snapshot.append_border (
                outline,
                /*Width of each boarder */ { 4, 4, 4, 4 },
                { foreground_color, foreground_color, foreground_color, foreground_color });

            /* Next, draw the hour hand.
             * We do this using tranforms again: Instead of computing where the angle
             * points to, we just rotate everything and then draw the hand as if it
             * was :00. We don't even need to care about am/pm here because rotations
             * just work.
             */
            snapshot.save ();
            snapshot.rotate (30 * now.get_hour () + 0.5f * now.get_minute ());
            outline.init_from_rect ({ { -2, -23 }, { 4, 25 } }, 2f);
            snapshot.push_rounded_clip (outline);
            snapshot.append_color (foreground_color, outline.bounds);
            snapshot.pop ();
            snapshot.restore ();

            /* And the same as above for the minute hand. Just make this one longer
             * so people can tell the hands apart.
             */
            snapshot.save ();
            snapshot.rotate (6 * now.get_minute ());
            outline.init_from_rect ({ { -2, -43 }, { 4, 45 } }, 2f);
            snapshot.push_rounded_clip (outline);
            snapshot.append_color (foreground_color, outline.bounds);
            snapshot.pop ();
            snapshot.restore ();

            /* and finally, the second indicator. */
            snapshot.save ();
            snapshot.rotate (6 * now.get_second ());
            outline.init_from_rect ({ { -2, -43 }, { 4, 10 } }, 2f);
            snapshot.push_rounded_clip (outline);
            snapshot.append_color (foreground_color, outline.bounds);
            snapshot.pop ();
            snapshot.restore ();

            /* And finally, don't forget to restore the initial save() that
             * we did for the initial transformations.
             */
            snapshot.restore ();
        }

        void start_ticking () {
            if (_ticking_id == 0) {
                _ticking = true;
                _ticking_id = GLib.Timeout.add_seconds (1, tick);
            }
        }

        void stop_ticking () {
            if (_ticking_id != 0) {
                _ticking = false;
                GLib.Source.remove (_ticking_id);
            }
        }

        bool tick () {
            this.queue_draw ();
            this.notify_property ("time");
            return GLib.Source.CONTINUE;
        }

        protected override void dispose () {
            base.dispose ();
            if (_ticking) {
                stop_ticking ();
            }
        }

        protected override void measure (Gtk.Orientation orientation,
                                         int for_size,
                                         out int minimum,
                                         out int natural,
                                         out int minimum_baseline,
                                         out int natural_baseline) {
            minimum = 100;
            natural = 100;
            minimum_baseline = natural_baseline = -1;
        }
    }
}

