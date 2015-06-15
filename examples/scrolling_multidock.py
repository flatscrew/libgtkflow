#!/usr/bin/python3

from gi.repository import GLib
from gi.repository import Gtk
from gi.repository import GFlow
from gi.repository import GtkFlow

import sys

class ExampleNode(GFlow.SimpleNode):
    def __new__(cls):
        x = GFlow.SimpleNode.new()
        x.__class__ = cls
        return x

class AddNode(ExampleNode):
    def add_summand(self, widget=None, data=None):
        summand_a = GFlow.SimpleSink.new(float(0))
        summand_a.set_name("operand %i"%(len(self.summands),))
        self.add_sink(summand_a)
        summand_a.connect("changed", self.do_calculations)
        self.summands.append(summand_a)
        self.do_calculations(None)
 
    def remove_summand(self, widget=None, data=None):
        if len(self.summands) == 0:
            return
        summand = self.summands[len(self.summands)-1]
        summand.disconnect_all()
        self.remove_sink(summand)
        self.summands.remove(summand)
        self.do_calculations(None)
        
       
    def __init__(self):
        self.summands = []
    
        self.result = GFlow.SimpleSource.new(float(0))
        self.result.set_name("result")
        self.add_source(self.result)

        self.add_button = Gtk.Button.new_with_mnemonic("Add")
        self.remove_button = Gtk.Button.new_with_mnemonic("Rem")
        self.btnbox = Gtk.Box.new(Gtk.Orientation.HORIZONTAL,0)
        self.btnbox.add(self.add_button)
        self.btnbox.add(self.remove_button)
        self.add_button.connect("clicked", self.add_summand)
        self.remove_button.connect("clicked", self.remove_summand)

        self.set_name("Operation")

    def do_calculations(self, dock, val=None):
        res = 0
        for summand in self.summands:
            try:
                val = summand.get_value()
                res += val
            except:
                self.result.invalidate()
                return
    
        self.result.set_value(res)

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
        
        try:
            val_a = self.summand_a.get_value()
            val_b = self.summand_b.get_value()
        except:
            self.result.invalidate()
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
            self.result.invalidate()

class NumberNode(ExampleNode):
    def __init__(self, number=0):
        self.number = GFlow.SimpleSource.new(float(number))
        self.number.set_valid()
        self.number.set_name("output")
        self.add_source(self.number)
        
        adjustment = Gtk.Adjustment(0, 0, 100, 1, 10, 0)
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

    def do_printing(self, dock):
        try:
            n = self.number.get_value()
            print (n)
            self.childlabel.set_text(str(n))
        except:
            self.childlabel.set_text("")
        
class Calculator(object):
    def __init__(self):
        w = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        self.nv = GtkFlow.NodeView.new()
        self.sw = Gtk.ScrolledWindow()

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

        self.sw.add(self.nv)
        vbox = Gtk.Box.new(Gtk.Orientation.VERTICAL, 0)
        vbox.pack_start(hbox, False, False, 0)
        vbox.pack_start(self.sw, True, True, 0)
 
        w.add(vbox)
        w.show_all()       
        w.connect("destroy", self.do_quit)
        Gtk.main()

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
