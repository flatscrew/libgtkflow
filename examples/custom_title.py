#!/usr/bin/python3

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GtkFlow', '0.10')
gi.require_version('GFlow', '0.10')

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
        self.titlestack = Gtk.Stack.new()
        self.title_entry = Gtk.Entry.new()
        self.title_entry.set_text("Custom Title")
        self.title_label = Gtk.Label.new("asdf")
        self.title_eventbox = Gtk.EventBox()
        self.title_eventbox.add(self.title_label)
        self.titlestack.add_named(self.title_entry, "titleentry")
        self.titlestack.add_named(self.title_eventbox, "titlelabel")
        self.title_entry.connect("activate", self.cb_save_title)
        self.title_eventbox.connect("button_press_event", self.cb_edit_title)
        self.titlestack.set_visible_child_name("titlelabel")


        self.summand_a = GFlow.SimpleSink.new(float(0))
        self.summand_b = GFlow.SimpleSink.new(float(0))
        self.summand_a.set_name("operand A")
        self.summand_b.set_name("operand B")
        self.add_sink(self.summand_a)
        self.add_sink(self.summand_b)
        self.val_a = None
        self.val_b = None

        self.result = GFlow.SimpleSource.with_type(float)
        self.result.set_name("result")
        self.add_source(self.result)
        self.result.set_value(None)

        operations = ["+", "-", "*", "/"]
        self.combobox = Gtk.ComboBoxText()
        self.combobox.connect("changed", self.do_calculations)
        self.combobox.set_entry_text_column(0)
        for op in operations:
            self.combobox.append_text(op)

        self.summand_a.connect("changed", self.do_calculations, "a")
        self.summand_b.connect("changed", self.do_calculations, "b")

        self.set_name("Operation")

    def cb_edit_title(self, *args, **kwargs):
        self.titlestack.set_visible_child_name("titleentry")
    def cb_save_title(self, *args, **kwargs):
        self.titlestack.set_visible_child_name("titlelabel")
        self.title_label.set_text(self.title_entry.get_text())

    def do_calculations(self, dock, val=None, flow_id=None, data=None):
        op = self.combobox.get_active_text() 

        if data == "a":
            self.val_a = val
        if data == "b":
            self.val_b = val

        if self.val_a is None or self.val_b is None:
            self.result.set_value(None)
            return

        if op == "+":
            self.result.set_value(self.val_a+self.val_b)
        elif op == "-":
            self.result.set_value(self.val_a-self.val_b)
        elif op == "*":
            self.result.set_value(self.val_a*self.val_b)
        elif op == "/":
            self.result.set_value(self.val_a/self.val_b)
        else:
            self.result.set_value(None)

class NumberNode(CalculatorNode):
    def __init__(self, number=0):
        self.number = GFlow.SimpleSource.with_type(float)
        self.number.set_name("output")
        self.add_source(self.number)

        adjustment = Gtk.Adjustment.new(0, 0, 100, 1, 10, 0)
        self.spinbutton = Gtk.SpinButton()
        self.spinbutton.set_adjustment(adjustment)
        self.spinbutton.set_size_request(50,20)
        self.spinbutton.connect("value_changed", self.do_value_changed)
        self.number.set_value(float(self.spinbutton.get_value()))

        self.set_name("NumberGenerator")

    def do_value_changed(self, widget=None, data=None, flow_id=None):
        self.number.set_value(float(self.spinbutton.get_value()))

class PrintNode(CalculatorNode):
    def __init__(self):
        self.number = GFlow.SimpleSink.new(float(0))
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
        self.nv.set_placeholder("Please click the buttons above to spawn nodes.")

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

        vbox = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
        vbox.pack_start(hbox, False, False, 0)
        vbox.pack_start(self.nv, True, True, 0)
 
        w.add(vbox)
        w.show_all()
        w.connect("destroy", self.do_quit)
        Gtk.main()

    def do_create_addnode(self, widget=None, data=None):
        n = OperationNode()
        self.nv.add_with_child(n, n.combobox, title=n.titlestack)
        self.nv.set_node_renderer(n, GtkFlow.NodeRendererType.DEFAULT)
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
