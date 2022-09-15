#!/usr/bin/env -S vala --pkg gtk+-3.0 --pkg gtkflow-0.10 --pkg gflow-0.10
// Run: $ ./minimal.vala
// Compile: $ valac minimal.vala --pkg gtk+-3.0 --pkg gflow-0.10 --pkg gtkflow-0.10
using Gtk;
using GFlow;
GtkFlow.NodeView nv;
void main(string[] args)
{
    Gtk.init(ref args);

    var window = new Window();
    window.set_default_size(400, 300);
    window.destroy.connect(Gtk.main_quit);
    var bar = new HeaderBar();
    bar.show_close_button = true;
    bar.title = "GTK Flow!";
    window.set_titlebar(bar);

    var sw = new ScrolledWindow(null,null);
    nv = new GtkFlow.NodeView();
    var btn = new Button.with_label("Add Node");
    var box = new Box(Orientation.VERTICAL,0);

    btn.clicked.connect(() => {
        var n = new GFlow.SimpleNode ();
        var sink_v = Value(Type.INT);
        var source_v = Value(Type.INT);
        var sink = new GFlow.SimpleSink.with_type(typeof(int));
        var source = new GFlow.SimpleSource.with_type(typeof(int));
        sink.name = "sink";
        source.name = "source";
        n.add_source(source);
        n.add_sink(sink);
        n.name = "node";
        nv.add_node(n);
    });

    sw.expand = true;
    bar.add(btn);
    box.add(sw);
    sw.add(nv);
    window.add(box);
    window.show_all();
    Gtk.main();
}
