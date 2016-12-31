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
                  vala_gir: 'GtkFlow-' + api + '.gir',
                  install: true)

gtkflow_inc = include_directories('.')

custom_target('gtkflow-typelib',
              command: [g_ir_compiler, '--output', '@OUTPUT@', meson.current_build_dir() + '/GtkFlow-' + api + '.gir',
                       '--shared-library', get_option('prefix') + '/' + get_option('libdir') + '/libgtkflow-'+ api +'.so'],
              output: 'GtkFlow-' + api + '.typelib',
              depends: gtkflow,
              install: true,
              install_dir: get_option('libdir') + '/girepository-1.0')

install_data(sources: meson.current_build_dir() + '/GtkFlow-' + api + '.gir',
             install_dir: get_option('datadir') + '/gir-1.0')

install_data(sources: meson.current_build_dir() + '/gtkflow-' + api + '.vapi',
             install_dir: get_option('datadir') + '/vala/vapi')

install_headers(meson.current_build_dir () + '/gtkflow-' + api + '.h',
                subdir: 'gtkflow-' + api)
install_data(sources: [meson.current_source_dir() + '/gtkflow-' + api + '.deps'],
             install_dir: get_option('datadir') + '/vala/vapi')

pkgconfig.generate(libraries: [gflow, gtkflow],
                   subdirs: 'gtkflow-' + api,
                   version: api,
                   name: 'gtkflow',
                   filebase: 'gtkflow-' + api,
                   requires: ['glib-2.0', 'gobject-2.0', 'gflow-' + api],
                   description: 'A library to create flowgraphs in GTK+')

if get_option('enable_valadoc')
    valadoc = find_program('valadoc')
    gtkflow_docs = custom_target('gtkflow_apidocs',
                                 depends: gflow,
                                 input: src,
                                 command: [valadoc, '-o', 'devhelp/gtkflow-' + api, '--doclet', 'devhelp', '@INPUT@',
                                 '--pkg', 'gtk+-3.0', '--vapidir=' + meson.current_build_dir() + '/../libgflow/', '--pkg', 'gflow-' + api,
                                 '--force'],
                                 output: 'devhelp')
    install_subdir(meson.current_build_dir() + '/../devhelp/gtkflow-' + api + '/gtkflow-' + api,
                   install_dir: get_option('datadir') + '/devhelp/books',
                   depends: [gtkflow_docs])
endif
