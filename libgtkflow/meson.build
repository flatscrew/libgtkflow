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

install_headers(meson.current_build_dir () + '/gtkflow-' + api + '.h',
                subdir: 'gtkflow-' + api)

pkgconfig.generate(libraries: [gflow, gtkflow],
                   subdirs: 'gtkflow-' + api,
                   version: api,
                   name: 'gtkflow',
                   filebase: 'gtkflow-' + api,
                   requires: ['glib-2.0', 'gobject-2.0', 'gflow-' + api],
                   description: 'A library to create flowgraphs in GTK+')
