#!/usr/bin/python3

import gi
gi.require_version('Gtk', '3.0')

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
        self.string_a = GFlow.SimpleSink.new("")
        self.string_b = GFlow.SimpleSink.new("")
        self.string_a.set_name("string A")
        self.string_b.set_name("string B")
        self.add_sink(self.string_a)
        self.add_sink(self.string_b)

        self.result = GFlow.SimpleSource.new("")
        self.result.set_name("output")
        self.add_source(self.result)
        self.result.set_value(None)

        self.string_a.connect("changed", self.do_concatenation)
        self.string_b.connect("changed", self.do_concatenation)
        self.set_name("Concatenation")


    def do_concatenation(self, dock, val=None):
        val_a = self.string_a.get_value(0) or ""
        val_b = self.string_b.get_value(0) or ""
        self.result.set_value(val_a+val_b)

class ConversionNode(ExampleNode):
    def __init__(self):
        self.sink = GFlow.SimpleSink.new(float(0))
        self.sink.set_name("input")
        self.add_sink(self.sink)

        self.source = GFlow.SimpleSource.new("")
        self.source.set_name("output")
        self.add_source(self.source)
        self.source.set_value(None)

        self.sink.connect("changed", self.do_conversion)
        self.set_name("Number2String")

    def do_conversion(self, dock, val=None):
        v = self.sink.get_value(0)
        if v is not None:
            self.source.set_value(str(v))
        else:
            self.source.set_value(None)

class StringNode(ExampleNode):
    def __init__(self):
        ExampleNode.__init__(self)

        self.source = GFlow.SimpleSource.new("")
        self.source.set_name("output")
        self.add_source(self.source)

        self.entry = Gtk.Entry()
        self.entry.connect("changed", self.do_changed)

        self.set_name("String")

    def do_changed(self, widget=None, data=None):
        self.source.set_value(self.entry.get_text())

class OperationNode(ExampleNode):
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

class NumberNode(ExampleNode):
    def __init__(self, number=0):
        self.number = GFlow.SimpleSource.new(float(number))
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
        self.sink = GFlow.SimpleSink.new("")
        self.sink.set_name("")
        self.sink.connect("changed", self.do_printing)
        self.add_sink(self.sink)

        self.childlabel = Gtk.Label()

        self.set_name("Output")

    def do_printing(self, dock, val=None):
        v = self.sink.get_value(0)
        if v is not None:
            self.childlabel.set_text(v)
        else:
            self.childlabel.set_text("")

class TypesExampleApplication(object):
    def __init__(self):
        w = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        self.nv = GtkFlow.NodeView.new()
        self.nv.set_show_types(True)

        hbox = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
        create_numbernode_button = Gtk.Button("Create NumberNode")
        create_numbernode_button.connect("clicked", self.do_create_numbernode)
        hbox.add(create_numbernode_button)
        create_addnode_button = Gtk.Button("Create OperationNode")
        create_addnode_button.connect("clicked", self.do_create_addnode)
        hbox.add(create_addnode_button)
        create_printnode_button = Gtk.Button("Create PrintNode")
        create_printnode_button.connect("clicked", self.do_create_printnode)
        hbox.add(create_printnode_button)
        create_concatnode_button = Gtk.Button("Create ConcatenationNode")
        create_concatnode_button.connect("clicked", self.do_create_concatnode)
        hbox.add(create_concatnode_button)
        create_stringnode_button = Gtk.Button("Create StringNode")
        create_stringnode_button.connect("clicked", self.do_create_stringnode)
        hbox.add(create_stringnode_button)
        create_conversionnode_button = Gtk.Button("Create ConversionNode")
        create_conversionnode_button.connect("clicked", self.do_create_conversionnode)
        hbox.add(create_conversionnode_button)

        hbox.add(Gtk.Separator())
        show_types_button = Gtk.Button("Show Types")
        show_types_button.connect("clicked", self.do_show_types)
        hbox.add(show_types_button)
        hide_types_button = Gtk.Button("Hide Types")
        hide_types_button.connect("clicked", self.do_hide_types)
        hbox.add(hide_types_button)


        vbox = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 0)
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
