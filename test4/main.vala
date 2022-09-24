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
    //var va = new Gtk.Adjustment(Gtk.Orientation.VERTICAL);
    //var ha = new Gtk.Adjustment(Gtk.Orientation.HORIZONTAL);

    var nv = new GtkFlow.NodeView();
    sw.child=nv;
    sw.vexpand=true;
    //vp.child=nv;

    btn.clicked.connect(()=>{
        var node = new GFlow.SimpleNode();
        node.name = "Testnode";
        try {
            var source1 = new GFlow.SimpleSource(1);
            source1.name = "quelle 1";
            node.add_source(source1);
            var source2 = new GFlow.SimpleSource(1);
            source2.name = "qualle 2";
            node.add_source(source2);
            var sink1 = new GFlow.SimpleSink(1);
            sink1.name = "abfluss 1";
            node.add_sink(sink1);
        } catch (GFlow.NodeError e) {
            warning("Couldn't build node");
        }
            
        nv.add(new GtkFlow.Node(node));   
    });

    win.child = box;
    box.append(btn);
    //box.homogeneous = true;
    box.append(sw);
    win.present();
  });
  return app.run(args);
} 

