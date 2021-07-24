#!/usr/bin/python3

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GFlow', '0.8')
gi.require_version('GtkFlow', '0.8')

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

class AddNode(ExampleNode):
    def add_summand(self, widget=None, data=None):
        summand_a = GFlow.SimpleSink.with_type(float)
        summand_a.set_name("operand %i"%(len(self.summands),))
        self.add_sink(summand_a)
        self.summands.append(summand_a)
        self.summands_values.append(None)
        summand_a.connect("changed", self.do_calculations, self.summands.index(summand_a))
        self.do_calculations(None)
 
    def remove_summand(self, widget=None, data=None):
        if len(self.summands) == 0:
            return
        summand = self.summands[len(self.summands)-1]
        summand.unlink_all()
        self.remove_sink(summand)
        self.summands.remove(summand)
        self.summands_values.remove(self.summands_values[-1])
        self.do_calculations(None)


    def __init__(self):
        self.summands = []
        self.summands_values = []

        self.result = GFlow.SimpleSource.with_type(float)
        self.result.set_name("result")
        self.add_source(self.result)
        self.result.set_value(None)

        self.add_button = Gtk.Button.new_with_mnemonic("Add")
        self.remove_button = Gtk.Button.new_with_mnemonic("Rem")
        self.btnbox = Gtk.Box.new(Gtk.Orientation.HORIZONTAL,0)
        self.btnbox.add(self.add_button)
        self.btnbox.add(self.remove_button)
        self.add_button.connect("clicked", self.add_summand)
        self.remove_button.connect("clicked", self.remove_summand)

        self.set_name("Operation")

    def do_calculations(self, dock, val=None, flow_id=None, affiliation=None):
        if len(self.summands) == 0:
            self.result.set_value(None)
            return

        if affiliation is not None:
            self.summands_values[affiliation] = val

        res = 0
        for val in self.summands_values:
            if val is None:
                self.result.set_value(None)
                return
            res += val

        self.result.set_value(res)

class NumberNode(ExampleNode):
    def __init__(self, number=0):
        self.number = GFlow.SimpleSource.with_type(float)
        self.number.set_name("output")
        self.add_source(self.number)

        adjustment = Gtk.Adjustment.new(0, 0, 100, 1, 10, 0)
        self.spinbutton = Gtk.SpinButton()
        self.spinbutton.set_adjustment(adjustment)
        self.spinbutton.set_size_request(50,20)
        self.spinbutton.connect("value_changed", self.do_value_changed)

        self.set_name("NumberGenerator")

    def do_value_changed(self, widget=None, data=None):
        self.number.set_value(float(self.spinbutton.get_value()))

class PrintNode(ExampleNode):
    def __init__(self):
        self.number = GFlow.SimpleSink.new(float(0))
        self.number.set_name("")
        self.number.connect("changed", self.do_printing)
        self.add_sink(self.number)

        self.childlabel = Gtk.Label()

        self.set_name("Output")

    def do_printing(self, dock, val=None, flow_id=None):
        if val is None:
            self.childlabel.set_text("")
        else:
            self.childlabel.set_text(str(val))

class Calculator(object):
    def __init__(self):
        w = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        self.nv = GtkFlow.NodeView.new()
        self.nv.connect_after("color-calculation", self.do_color_request)
        self.nv.set_placeholder("Please click the buttons above to spawn nodes.")
        self.sw = Gtk.ScrolledWindow()

        hbox = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
        create_numbernode_button = Gtk.Button.new_with_label("Create NumberNode")
        create_numbernode_button.connect("clicked", self.do_create_numbernode)
        hbox.add(create_numbernode_button)
        create_addnode_button = Gtk.Button.new_with_label("Create OperationNode")
        create_addnode_button.connect("clicked", self.do_create_addnode)
        hbox.add(create_addnode_button)
        create_printnode_button = Gtk.Button.new_with_label("Create PrintNode")
        create_printnode_button.connect("clicked", self.do_create_printnode)
        hbox.add(create_printnode_button)

        self.sw.add(self.nv)
        vbox = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
        vbox.pack_start(hbox, False, False, 0)
        vbox.pack_start(self.sw, True, True, 0)
 
        w.add(vbox)
        w.show_all()
        w.connect("destroy", self.do_quit)
        Gtk.main()

    def do_color_request(self, nodeview, value):
        if type(value) == float:
            if value > 100:
                return "ff0000"
            elif value < 0:
                return "000000"
            else:
                return "%02x0000"%(int(value/100 * 255),)
        print (type (value))
        return "000000"

    def do_create_addnode(self, widget=None, data=None):
        n = AddNode()
        self.nv.add_with_child(n, n.btnbox)
    def do_create_numbernode(self, widget=None, data=None):
        n = NumberNode()
        self.nv.add_with_child(n, n.spinbutton)
    def do_create_printnode(self, widget=None, data=None):
        n = PrintNode()
        self.nv.add_with_child(n, n.childlabel)
    def do_quit(self, widget=None, data=None):
        Gtk.main_quit()
        sys.exit(0)

if __name__ == "__main__":
    Calculator()
