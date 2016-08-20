#!/usr/bin/python3

"""
This example shall explain how it is possible to do use cyclic graphs in
libgtkflow. This example features a counter-node that will trigger itself
to count up to a specific numeric value (self.target). To achieve the desired
effect, please connect the counted-source with the clock-sink, so the node
will propagate the desired signal to itself. 
"""

from gi.repository import GLib
from gi.repository import Gtk
from gi.repository import GFlow
from gi.repository import GtkFlow

import sys

class ExampleNode(GFlow.SimpleNode):
    def __new__(cls, *args, **kwargs):
        x = GFlow.SimpleNode.new()
        x.__class__ = cls
        return x

class StarterNode(ExampleNode):
    def __init__(self):
        self.emitter = GFlow.SimpleSource.new(float(0))
        self.emitter.set_name("emitter")
        self.add_source(self.emitter)

        self.button = Gtk.Button.new_with_label("Start!")
        self.button.connect("clicked", self.do_send_start)

        self.set_name("Counter")

    def do_send_start(self, dock, val=None):
        self.emitter.set_value(1.0)

class CountNode(ExampleNode):
    def __init__(self):
        self.counter = 0.0
        self.target = 10.0

        self.enable = GFlow.SimpleSink.new(float(0))
        self.clock = GFlow.SimpleSink.new(float(0))
        self.enable.set_name("enable")
        self.clock.set_name("clock")
        self.add_sink(self.enable)
        self.add_sink(self.clock)    
    
        self.result = GFlow.SimpleSource.new(float(0))
        self.counted = GFlow.SimpleSource.new(float(0))
        self.result.set_name("result")
        self.counted.set_name("counted")
        self.add_source(self.result)
        self.add_source(self.counted)

        self.enable.connect("changed", self.do_calculations)
        self.clock.connect("changed", self.do_calculations)

        self.set_name("Counter")

    def do_calculations(self, dock, val=None):
        try:
            enable = self.enable.get_value()
            if enable != 1.0:
                return
        except:
            return
        
        if self.counter < self.target:
            self.counter += 1.0
            self.counted.set_value(self.counter)
        self.result.set_value(self.counter)

class PrintNode(ExampleNode):
    def __init__(self):
        self.number = GFlow.SimpleSink.new(float(0))
        self.number.set_name("input")
        self.number.connect("changed", self.do_printing)
        self.add_sink(self.number)

        self.childlabel = Gtk.Label()

        self.set_name("Output")

    def do_printing(self, dock):
        try:
            n = self.number.get_value()
            print (n)
            self.childlabel.set_text(str(n))
        except GLib.Error as e:
            self.childlabel.set_text("")

class CountDemo(object):
    def __init__(self):
        w = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        self.nv = GtkFlow.NodeView.new()

        # This deactivates nodeview's self-check for recursions
        self.nv.set_allow_recursion(True)

        hbox = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
        create_starternode_button = Gtk.Button("Create StarterNode")
        create_starternode_button.connect("clicked", self.do_create_starternode)
        hbox.add(create_starternode_button)
        create_countnode_button = Gtk.Button("Create CountNode")
        create_countnode_button.connect("clicked", self.do_create_countnode)
        hbox.add(create_countnode_button)
        create_printnode_button = Gtk.Button("Create PrintNode")
        create_printnode_button.connect("clicked", self.do_create_printnode)
        hbox.add(create_printnode_button)

        vbox = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
        vbox.pack_start(hbox, False, False, 0)
        vbox.pack_start(self.nv, True, True, 0)
 
        w.add(vbox)
        w.add(self.nv)
        w.show_all()       
        w.connect("destroy", self.do_quit)
        Gtk.main()

    def do_create_starternode(self, widget=None, data=None):
        n = StarterNode()
        self.nv.add_with_child(n, n.button)
    def do_create_countnode(self, widget=None, data=None):
        n = CountNode()
        self.nv.add_node(n)
    def do_create_printnode(self, widget=None, data=None):
        n = PrintNode()
        self.nv.add_with_child(n, n.childlabel)
    def do_quit(self, widget=None, data=None):
        Gtk.main_quit()
        sys.exit(0)

if __name__ == "__main__":
    CountDemo()
