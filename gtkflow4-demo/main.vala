class TestNode : GFlow.SimpleNode {
    public GFlow.SimpleSource source1;
    public GFlow.SimpleSource source2;
    public GFlow.SimpleSink sink1;


    public TestNode(string name) {
        this.name = name;

        try {
            this.source1 = new GFlow.SimpleSource(typeof(int));
            this.source1.name = "%s quelle 1".printf(name);
            this.add_source(source1);

            this.source2 = new GFlow.SimpleSource(typeof(int));
            this.source2.name = "%s quelle 2".printf(name);
            this.add_source(source2);

            this.sink1 = new GFlow.SimpleSink(1);
            this.sink1.name = "%s abfluss 2".printf(name);
            this.add_sink(sink1);
            this.sink1.max_sources = 10;
        } catch (GFlow.NodeError e) {
            warning("Couldn't build node");
        }
    }

    public void register_colors(GtkFlow.NodeView nv) {
        var src_widget1 = nv.retrieve_dock(this.source1);
        var src_widget2 = nv.retrieve_dock(this.source2);
        var snk_widget1 = nv.retrieve_dock(this.sink1);
        src_widget1.resolve_color.connect_after((d,v)=>{ return {1.0f,0.0f,0.0f,1.0f};});
        src_widget2.resolve_color.connect_after((d,v)=>{ return {0.0f,1.0f,0.0f,1.0f};});
        snk_widget1.resolve_color.connect_after((d,v)=>{ return {0.0f,0.0f,1.0f,1.0f};});
    }
}

int main (string[] args) {
  var app = new Gtk.Application(
    "de.grindhold.GtkFlow4Example",
    ApplicationFlags.FLAGS_NONE
  );

  app.activate.connect(() => {
    var win = new Gtk.ApplicationWindow(app);

    var btn = new Gtk.Button.with_label("Spawn Node");
    var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    var sw = new Gtk.ScrolledWindow();

    var nv = new GtkFlow.NodeView();
    var mm = new GtkFlow.Minimap();
    sw.child=nv;
    sw.vexpand=true;

    mm.nodeview = nv;

    btn.clicked.connect(()=>{
        var node = new TestNode("TestNode");
        var nn = new GtkFlow.Node(node);
        var d = nn.retrieve_dock(node.source1);
        d.set_docklabel(new Gtk.Scale(Gtk.Orientation.HORIZONTAL, new Gtk.Adjustment(0.0,0.0,1.0,0.01,0.1,0.1)));
        d = nn.retrieve_dock(node.source2);
        d.set_docklabel(new Gtk.SpinButton.with_range(0.0,1.0,0.01));
        var CSS = ".gtkflow_node { background: linear-gradient(0deg, rgba(150,111,136,1) 0%, rgba(175,175,222,1) 35%, rgba(0,212,255,1) 100%); }";
        Gtk.CssProvider custom_css = new Gtk.CssProvider();
        custom_css.load_from_data(CSS.data);
        nn.get_style_context().add_provider(custom_css,Gtk.STYLE_PROVIDER_PRIORITY_USER);
        nv.add(nn);
    });

    var n1 = new TestNode("foo");
    var n2 = new TestNode("bar");
    var gn1 = new GtkFlow.Node(n1);
    gn1.add_child(new Gtk.Button.with_label("EEEEEE!"));
    gn1.highlight_color = {0.6f,1.0f,0.0f,0.3f};
    nv.add(gn1);
    n1.register_colors(nv);
    nv.add(new GtkFlow.Node(n2));
    n2.register_colors(nv);

    try {
        n1.source1.link(n2.sink1);
    } catch (Error e) {
        warning("could not link nodees:"+ e.message);
    }

    win.child = box;
    box.append(btn);
    box.append(mm);
    box.append(sw);
    win.present();
  });
  return app.run(args);
}

