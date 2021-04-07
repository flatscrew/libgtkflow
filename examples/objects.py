#!/usr/bin/python3

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GtkFlow', '0.8')
gi.require_version('GFlow', '0.8')

from gi.repository import GLib
from gi.repository import Gtk
from gi.repository import GFlow
from gi.repository import GtkFlow

import sys

class Node(GFlow.SimpleNode):
    def __new__(cls, *args, **kwargs):
        x = GFlow.SimpleNode.new()
        x.__class__ = cls
        return x

class Point(object):
    def __init__(self, x=0, y=0):
        self.x = x
        self.y = y

class PointConstructorNode(Node):
    def __init__(self):
        self.x_sink = GFlow.SimpleSink.with_type(float)
        self.y_sink = GFlow.SimpleSink.with_type(float)
        self.x_sink.set_name("X")
        self.y_sink.set_name("Y")
        self.x = 0.0
        self.y = 0.0
        self.add_sink(self.x_sink)
        self.add_sink(self.y_sink)

        self.result = GFlow.SimpleSource.with_type(object)
        self.result.set_name("result")
        self.add_source(self.result)
        self.result.set_value(None)

        self.x_sink.connect("changed", self.do_calculations, "x")
        self.y_sink.connect("changed", self.do_calculations, "y")

        self.set_name("Point Constructor")

    def do_calculations(self, dock, val=None, flow_id=None, affiliation=None):
        if affiliation == "x":
            self.x = val
        elif affiliation == "y":
            self.y = val
        else:
            return

        if self.x is None or self.y is None:
            self.result.set_value(None)
            return

        p = Point(x=self.x, y=self.y)
        self.result.set_value(p)

class PointSplitterNode(Node):
    def __init__(self):
        self.p_sink = GFlow.SimpleSink.new(object)
        self.p_sink.set_name("point")
        self.p = None
        self.add_sink(self.p_sink)

        self.result_x = GFlow.SimpleSource.with_type(float)
        self.result_y = GFlow.SimpleSource.with_type(float)
        self.result_x.set_name("X")
        self.result_y.set_name("Y")
        self.add_source(self.result_x)
        self.add_source(self.result_y)
        self.result_x.set_value(None)
        self.result_y.set_value(None)

        self.p_sink.connect("changed", self.do_calculations)

        self.set_name("Point Splitter")

    def do_calculations(self, dock, val=None, flow_id=None):
        self.p = val
        if val is None:
            self.result_x.set_value(None)
            self.result_y.set_value(None)
            return

        self.result_x.set_value(self.p.x)
        self.result_y.set_value(self.p.y)


class NumberNode(Node):
    def __init__(self, number=0.0):
        self.number = GFlow.SimpleSource.with_type(float)
        self.number.set_value(number)
        self.number.set_name("output")
        self.add_source(self.number)

        adjustment = Gtk.Adjustment.new(0, 0, 100, 1, 10, 0)
        self.spinbutton = Gtk.SpinButton()
        self.spinbutton.set_adjustment(adjustment)
        self.spinbutton.set_size_request(50,20)
        self.spinbutton.connect("value_changed", self.do_value_changed)
        self.number.set_value(float(self.spinbutton.get_value()))

        self.set_name("NumberGenerator")

    def do_value_changed(self, widget=None, data=None):
        self.number.set_value(float(self.spinbutton.get_value()))

class PrintNode(Node):
    def __init__(self):
        self.number = GFlow.SimpleSink.with_type(float)
        self.number.set_name("input")
        self.number.connect("changed", self.do_printing)
        self.add_sink(self.number)

        self.childlabel = Gtk.Label()

        self.set_name("Output")

    def do_printing(self, dock, val=None, flow_id=None):
        if val is not None:
            self.childlabel.set_text(str(val))
        else:
            self.childlabel.set_text("")

class Calculator(object):
    def __init__(self):
        w = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        self.nv = GtkFlow.NodeView.new()

        self.nv.set_show_types(True)

        hbox = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
        create_numbernode_button = Gtk.Button.new_with_label("Create NumberNode")
        create_numbernode_button.connect("clicked", self.do_create_numbernode)
        hbox.add(create_numbernode_button)
        create_constructor_button = Gtk.Button.new_with_label("Create Constructor")
        create_constructor_button.connect("clicked", self.do_create_constructor)
        hbox.add(create_constructor_button)
        create_splitter_button = Gtk.Button.new_with_label("Create Splitter")
        create_splitter_button.connect("clicked", self.do_create_splitter)
        hbox.add(create_splitter_button)
        create_printnode_button = Gtk.Button.new_with_label("Create PrintNode")
        create_printnode_button.connect("clicked", self.do_create_printnode)
        hbox.add(create_printnode_button)

        vbox = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
        vbox.pack_start(hbox, False, False, 0)
        vbox.pack_start(self.nv, True, True, 0)
 
        w.add(vbox)
        w.show_all()
        w.connect("destroy", self.do_quit)
        Gtk.main()

    def do_create_constructor(self, widget=None, data=None):
        n = PointConstructorNode()
        self.nv.add_node(n)
        self.nv.set_node_renderer(n, GtkFlow.NodeRendererType.DOCKLINE)
    def do_create_splitter(self, widget=None, data=None):
        n = PointSplitterNode()
        self.nv.add_node(n)
        self.nv.set_node_renderer(n, GtkFlow.NodeRendererType.DOCKLINE)
    def do_create_numbernode(self, widget=None, data=None):
        n = NumberNode()
        self.nv.add_with_child(n, n.spinbutton)
        self.nv.set_node_renderer(n, GtkFlow.NodeRendererType.DOCKLINE)
    def do_create_printnode(self, widget=None, data=None):
        n = PrintNode()
        self.nv.add_with_child(n, n.childlabel)
    def do_quit(self, widget=None, data=None):
        Gtk.main_quit()
        sys.exit(0)

if __name__ == "__main__":
    Calculator()
