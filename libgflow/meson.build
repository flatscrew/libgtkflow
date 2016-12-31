src = files([
    'gflow-dock.vala',
    'gflow-node.vala',
    'gflow-simple-node.vala',
    'gflow-simple-sink.vala',
    'gflow-simple-source.vala',
    'gflow-sink.vala',
    'gflow-source.vala',
])

gflow = library('gflow-' + api,
                src,
                dependencies: [glib, gobject],
                vala_gir: 'GFlow-' + api + '.gir',
                install: true)

gflow_inc = include_directories('.')

# TODO: figure out how specify gir as input
custom_target('gflow-typelib',
              command: [g_ir_compiler, '--output', '@OUTPUT@', meson.current_build_dir() + '/GFlow-' + api + '.gir',
                       '--shared-library', get_option('prefix') + '/' + get_option('libdir') + '/libgflow-'+ api +'.so'],
              output: 'GFlow-' + api + '.typelib',
              depends: gflow,
              install: true,
              install_dir: get_option('libdir') + '/girepository-1.0')

install_data(sources: meson.current_build_dir() + '/GFlow-' + api + '.gir',
             install_dir: get_option('datadir') + '/gir-1.0')

install_data(sources: meson.current_build_dir() + '/gflow-' + api + '.vapi',
             install_dir: get_option('datadir') + '/vala/vapi')

install_headers(meson.current_build_dir () + '/gflow-' + api + '.h',
                subdir: 'gflow-' + api)

install_data(sources: [meson.current_source_dir() + '/gflow-' + api + '.deps'],
             install_dir: get_option('datadir') + '/vala/vapi')

pkgconfig.generate(libraries: gflow,
                   subdirs: 'gflow-' + api,
                   version: api,
                   name: 'gflow',
                   filebase: 'gflow-' + api,
                   requires: ['glib-2.0', 'gobject-2.0'],
                   description: 'Flow Node Library')

if get_option('enable_valadoc')
    valadoc = find_program('valadoc')
    gflow_docs = custom_target('gflow_apidocs',
                               input: src,
                               command: [valadoc, '-o', 'devhelp/gflow-' + api, '--doclet', 'devhelp', '@INPUT@', '--force'],
                               output: 'devhelp')
    install_subdir(meson.current_build_dir() + '/../devhelp/gflow-' + api + '/gflow-' + api,
                   install_dir: get_option('datadir') + '/devhelp/books',
                   depends: [gflow_docs])
endif
