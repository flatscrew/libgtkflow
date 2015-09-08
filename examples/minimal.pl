use Glib::Object::Introspection;
Glib::Object::Introspection->setup(
    basename => 'Gtk',
    version => '3.0',
    package => 'Gtk');
Glib::Object::Introspection->setup(
    basename => 'GFlow',
    version => '0.2',
    package => 'GFlow');
Glib::Object::Introspection->setup(
    basename => 'GtkFlow',
    version => '0.2',
    package => 'GtkFlow');


Gtk::init(\@ARGV);

my $win = Gtk::Window->new('toplevel');
my $button = Gtk::Button->new_with_label("Foo");
my $vbox = Gtk::VBox->new('horizontal',0);
my $sw = Gtk::ScrolledWindow->new;
my $nodeview = GtkFlow::NodeView->new();
my $node, $wrap1, $wrap2, $source, $sink;
$button->signal_connect(clicked=>sub{
    my $n = create_node();
    print $n;
    $nodeview->add_node($n);
});

sub create_node {
    $node = new GFlow::SimpleNode;
    $wrap1 = Glib::Object::Introspection::GValueWrapper->new("Glib::Int", 0);
    $wrap2 = Glib::Object::Introspection::GValueWrapper->new("Glib::Int", 0);
    $source = GFlow::SimpleSource->new($wrap2);
    $source->set_name("source");
    $sink = GFlow::SimpleSink->new($wrap1);
    $sink->set_name("sink");

    $node->add_source($source);
    $node->add_sink($sink);
    $node->set_name("foo");
    return $node
}

$sw->add($nodeview);
$vbox->pack_start($button, 0, 0, 0);
$vbox->pack_start($sw, 1, 1, 1);
$win->add($vbox);
$win->show_all;
Gtk::main();
exit 0;
