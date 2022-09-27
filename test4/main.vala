class TestNode : GFlow.SimpleNode {
    public GFlow.Source source1;
    public GFlow.Source source2;
    public GFlow.Sink sink1;

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
        } catch (GFlow.NodeError e) {
            warning("Couldn't build node");
        }
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
    sw.child=nv;
    sw.vexpand=true;

    btn.clicked.connect(()=>{
        var node = new TestNode("TestNode");
        nv.add(new GtkFlow.Node(node));   
    });

    var n1 = new TestNode("foo");
    var n2 = new TestNode("bar");
    var gn1 = new GtkFlow.Node(n1);
    gn1.add_child(new Gtk.Button.with_label("EEEEEE!"));
    nv.add(gn1);
    nv.add(new GtkFlow.Node(n2));

    try {
        n1.source1.link(n2.sink1);
    } catch (Error e) {
        warning("could not link nodees:"+ e.message);
    }

    win.child = box;
    box.append(btn);
    box.append(sw);
    win.present();
  });
  return app.run(args);
} 

