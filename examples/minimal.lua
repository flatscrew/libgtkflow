#! /usr/bin/env lua

# XXX:This example is outdated and uses libgtkflow in a pre-0.8-way

# TODO: fix this example. use the .with_type-constructor of Sources and Sinks


local lgi = require 'lgi'
local GObject = lgi.require('GObject')
local Gtk = lgi.require('Gtk')
local GFlow = lgi.require('GFlow')
local GtkFlow = lgi.require('GtkFlow')

local window = Gtk.Window {
   title = 'window',
   default_width = 400,
   default_height = 300,
   on_destroy = Gtk.main_quit
}

local sw = Gtk.ScrolledWindow {}
local nv = GtkFlow.NodeView.new()

local button =  Gtk.Button { label = 'Add Node' }
function button:on_clicked()
   local n = GFlow.SimpleNode {}
   local sink_v = GObject.Value(GObject.Type.INT,0)
   local source_v = GObject.Value(GObject.Type.INT,0)
   local sink = GFlow.SimpleSink.new(sink_v)
   local source = GFlow.SimpleSource.new(source_v)
   sink:set_name("sink")
   source:set_name("source")
   n:add_source(source)
   n:add_sink(sink)
   n:set_name("node")
   nv:add_node(n)
end

local vbox = Gtk.VBox()
sw:add(nv)
vbox:pack_start(button, false, false, 0)
vbox:pack_start(sw, true, true, 1)
window:add(vbox)

window:show_all()
Gtk.main() 
