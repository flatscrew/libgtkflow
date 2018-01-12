#!/usr/bin/python3

from gi.repository import GLib
from gi.repository import Gtk
from gi.repository import GFlow
from gi.repository import GtkFlow

import sys

class CalculatorNode(GFlow.SimpleNode):
    def __new__(cls, *args, **kwargs):
        x = GFlow.SimpleNode.new()
        x.__class__ = cls
        return x

class OperationNode(CalculatorNode):
    def __init__(self):
        self.summand_a = GFlow.SimpleSink.new(float(0))
        self.summand_b = GFlow.SimpleSink.new(float(0))
        self.summand_a.set_name("operand A")
        self.summand_b.set_name("operand B")
        self.add_sink(self.summand_a)
        self.add_sink(self.summand_b)

        self.result = GFlow.SimpleSource.new(float(0))
        self.result.set_name("result")
        self.add_source(self.result)
        self.result.set_value(None)

        operations = ["+", "-", "*", "/"]
        self.combobox = Gtk.ComboBoxText()
        self.combobox.connect("changed", self.do_calculations)
        self.combobox.set_entry_text_column(0)
        for op in operations:
            self.combobox.append_text(op)

        self.summand_a.connect("changed", self.do_calculations)
        self.summand_b.connect("changed", self.do_calculations)

        self.set_name("Operation")

    def do_calculations(self, dock, val=None):
        op = self.combobox.get_active_text() 

        val_a = self.summand_a.get_value(0)
        val_b = self.summand_b.get_value(0)
        if val_a is None or val_b is None:
            self.result.set_value(None)
            return

        if op == "+":
            self.result.set_value(val_a+val_b)
        elif op == "-":
            self.result.set_value(val_a-val_b)
        elif op == "*":
            self.result.set_value(val_a*val_b)
        elif op == "/":
            self.result.set_value(val_a/val_b)
        else:
            self.result.set_value(None)

class NumberNode(CalculatorNode):
    def __init__(self, number=0):
        self.number = GFlow.SimpleSource.new(float(number))
        self.number.set_name("output")
        self.add_source(self.number)

        adjustment = Gtk.Adjustment(0, 0, 100, 1, 10, 0)
        self.spinbutton = Gtk.SpinButton()
        self.spinbutton.set_adjustment(adjustment)
        self.spinbutton.set_size_request(50,20)
        self.spinbutton.connect("value_changed", self.do_value_changed)
        self.number.set_value(float(self.spinbutton.get_value()))

        self.set_name("NumberGenerator")

    def do_value_changed(self, widget=None, data=None):
        self.number.set_value(float(self.spinbutton.get_value()))

class PrintNode(CalculatorNode):
    def __init__(self):
        self.number = GFlow.SimpleSink.new(float(0))
        self.number.set_name("input")
        self.number.connect("changed", self.do_printing)
        self.add_sink(self.number)

        self.childlabel = Gtk.Label()

        self.set_name("Output")

    def do_printing(self, dock):
        n = self.number.get_value(0)
        if n is not None:
            self.childlabel.set_text(str(n))
        else:
            self.childlabel.set_text("")

class Calculator(object):
    def __init__(self):
        w = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        self.nv = GtkFlow.NodeView.new()

        hbox = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
        create_numbernode_button = Gtk.Button("Create NumberNode")
        create_numbernode_button.connect("clicked", self.do_create_numbernode)
        hbox.add(create_numbernode_button)
        create_addnode_button = Gtk.Button("Create OperationNode")
        create_addnode_button.connect("clicked", self.do_create_addnode)
        hbox.add(create_addnode_button)
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

    def do_create_addnode(self, widget=None, data=None):
        n = OperationNode()
        self.nv.add_with_child(n, n.combobox)
        self.nv.set_node_renderer(n, GtkFlow.DocklineNodeRenderer())
    def do_create_numbernode(self, widget=None, data=None):
        n = NumberNode()
        self.nv.add_with_child(n, n.spinbutton)
        self.nv.set_node_renderer(n, GtkFlow.DocklineNodeRenderer())
    def do_create_printnode(self, widget=None, data=None):
        n = PrintNode()
        self.nv.add_with_child(n, n.childlabel)
    def do_quit(self, widget=None, data=None):
        Gtk.main_quit()
        sys.exit(0)

if __name__ == "__main__":
    Calculator()
