int main (string[] args) {
  var app = new Gtk.Application(
    "de.grindhold.GtkFlow4Example",
    ApplicationFlags.FLAGS_NONE
  );
  
  app.activate.connect(() => {
    var win = new Gtk.ApplicationWindow(app);

    var btn = new Gtk.Button.with_label("Hello World");
    var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    var nv = new GtkFlow.NodeView();

    btn.clicked.connect(()=>{
        nv.add(new GtkFlow.Node());   
    });

    win.child = box;
    box.append(btn);
    //box.homogeneous = true;
    box.append(nv);
    win.present();
  });
  return app.run(args);
} 

