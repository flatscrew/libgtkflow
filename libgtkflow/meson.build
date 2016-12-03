src = files([
    'dock_renderer.vala',
    'node_renderer.vala',
    'node.vala',
    'nodeview.vala',
    'drawinghelper.c'
])

gtkflow = library('gtkflow-'+api,
                  src,
                  dependencies: [glib, gobject, gtk, math],
                  link_with: gflow,
                  include_directories: gflow_inc,
                  install: true)
