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
                  vala_gir: 'gtkflow-' + api + '.gir',
                  install: true)

gtkflow_inc = include_directories('.')

custom_target('gtkflow-typelib',
              command: [g_ir_compiler, '--output', '@OUTPUT@', meson.current_build_dir() + '/gtkflow-' + api + '.gir'],
              output: 'gtkflow-' + api + '.typelib',
              depends: gtkflow,
              install: true,
              install_dir: get_option('libdir') + '/girepository-1.0')

install_data(sources: meson.current_build_dir() + '/gtkflow-' + api + '.gir',
             install_dir: get_option('datadir') + '/gir-1.0')

install_data(sources: meson.current_build_dir() + '/gtkflow-' + api + '.vapi',
             install_dir: get_option('datadir') + '/vala/vapi')
