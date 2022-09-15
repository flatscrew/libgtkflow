#!/usr/bin/python3

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GFlow', '0.10')
gi.require_version('GtkFlow', '0.10')

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

class ConcatNode(ExampleNode):
    def __init__(self):
        self.string_a = GFlow.SimpleSink.with_type(str)
        self.string_b = GFlow.SimpleSink.with_type(str)
        self.string_a.set_name("string A")
        self.string_b.set_name("string B")
        self.add_sink(self.string_a)
        self.add_sink(self.string_b)
        self.val_a = None
        self.val_b = None

        self.result = GFlow.SimpleSource.with_type(str)
        self.result.set_name("output")
        self.add_source(self.result)
        self.result.set_value(None)

        self.string_a.connect("changed", self.do_concatenation, "a")
        self.string_b.connect("changed", self.do_concatenation, "b")
        self.set_name("Concatenation")


    def do_concatenation(self, dock, val=None, flow_id=None, affiliation=None):
        if affiliation == "a":
            self.val_a = val
        if affiliation == "b":
            self.val_b = val
        val_a = self.val_a or ""
        val_b = self.val_b or ""
        self.result.set_value(val_a+val_b)

class ConversionNode(ExampleNode):
    def __init__(self):
        self.sink = GFlow.SimpleSink.with_type(float)
        self.sink.set_name("input")
        self.add_sink(self.sink)

        self.source = GFlow.SimpleSource.with_type(str)
        self.source.set_name("output")
        self.add_source(self.source)
        self.source.set_value(None)

        self.sink.connect("changed", self.do_conversion)
        self.set_name("Number2String")

    def do_conversion(self, dock, val=None, flow_id=None):
        if val is not None:
            self.source.set_value(str(val))
        else:
            self.source.set_value(None)

class StringNode(ExampleNode):
    def __init__(self):
        ExampleNode.__init__(self)

        self.source = GFlow.SimpleSource.with_type(str)
        self.source.set_name("output")
        self.add_source(self.source)

        self.entry = Gtk.Entry()
        self.entry.connect("changed", self.do_changed)

        self.set_name("String")

    def do_changed(self, widget=None, data=None):
        self.source.set_value(self.entry.get_text())

class OperationNode(ExampleNode):
    def __init__(self):
        self.summand_a = GFlow.SimpleSink.with_type(float)
        self.summand_b = GFlow.SimpleSink.with_type(float)
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


    def do_calculations(self, dock, val=None, flow_id=None, affiliation=None):
        op = self.combobox.get_active_text()

        if affiliation == "a":
            self.val_a = val
        if affiliation == "b":
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

    def do_value_changed(self, widget=None, data=None, flow_id=None):
        self.number.set_value(float(self.spinbutton.get_value()))

class PrintNode(ExampleNode):
    def __init__(self):
        self.sink = GFlow.SimpleSink.with_type(str)
        self.sink.set_name("")
        self.sink.connect("changed", self.do_printing)
        self.add_sink(self.sink)

        self.childlabel = Gtk.Label()

        self.set_name("Output")

    def do_printing(self, dock, val=None, flow_id=None):
        if val is not None:
            self.childlabel.set_text(val)
        else:
            self.childlabel.set_text("")

class TypesExampleApplication(object):
    def __init__(self):
        w = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        self.nv = GtkFlow.NodeView.new()
        self.nv.set_show_types(True)
        self.nv.set_placeholder("Please click the buttons above to spawn nodes.")

        hbox = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
        create_numbernode_button = Gtk.Button.new_with_label("Create NumberNode")
        create_numbernode_button.connect("clicked", self.do_create_numbernode)
        hbox.add(create_numbernode_button)
        create_addnode_button = Gtk.Button.new_with_label("Create OperationNode")
        create_addnode_button.connect("clicked", self.do_create_addnode)
        hbox.add(create_addnode_button)
        create_printnode_button = Gtk.Button.new_with_label("Create PrintNode")
        create_printnode_button.connect("clicked", self.do_create_printnode)
        hbox.add(create_printnode_button)
        create_concatnode_button = Gtk.Button.new_with_label("Create ConcatenationNode")
        create_concatnode_button.connect("clicked", self.do_create_concatnode)
        hbox.add(create_concatnode_button)
        create_stringnode_button = Gtk.Button.new_with_label("Create StringNode")
        create_stringnode_button.connect("clicked", self.do_create_stringnode)
        hbox.add(create_stringnode_button)
        create_conversionnode_button = Gtk.Button.new_with_label("Create ConversionNode")
        create_conversionnode_button.connect("clicked", self.do_create_conversionnode)
        hbox.add(create_conversionnode_button)

        hbox.add(Gtk.Separator())
        show_types_button = Gtk.Button.new_with_label("Show Types")
        show_types_button.connect("clicked", self.do_show_types)
        hbox.add(show_types_button)
        hide_types_button = Gtk.Button.new_with_label("Hide Types")
        hide_types_button.connect("clicked", self.do_hide_types)
        hbox.add(hide_types_button)


        vbox = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
        vbox.pack_start(hbox, False, False, 0)
        vbox.pack_start(self.nv, True, True, 0)

        w.add(vbox)
        w.show_all()
        w.connect("destroy", self.do_quit)
        Gtk.main()

    def do_create_addnode(self, widget=None, data=None):
        n = OperationNode()
        self.nv.add_with_child(n, n.combobox)
    def do_create_numbernode(self, widget=None, data=None):
        n = NumberNode()
        self.nv.add_with_child(n, n.spinbutton)
    def do_create_printnode(self, widget=None, data=None):
        n = PrintNode()
        self.nv.add_with_child(n, n.childlabel)
    def do_create_concatnode(self, widget=None, data=None):
        n = ConcatNode()
        self.nv.add_node(n)
    def do_create_stringnode(self, widget=None, data=None):
        n = StringNode()
        self.nv.add_with_child(n, n.entry)
    def do_create_conversionnode(self, widget=None, data=None):
        self.nv.add_node(ConversionNode())

    def do_show_types(self, widget=None, data=None):
        self.nv.set_show_types(True)
    def do_hide_types(self, widget=None, data=None):
        self.nv.set_show_types(False)

    def do_quit(self, widget=None, data=None):
        Gtk.main_quit()
        sys.exit(0)

if __name__ == "__main__":
    TypesExampleApplication()
