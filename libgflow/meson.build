src = files([
    'gflow-dock.vala',
    'gflow-node.vala',
    'gflow-simple-node.vala',
    'gflow-simple-sink.vala',
    'gflow-simple-source.vala',
    'gflow-sink.vala',
    'gflow-source.vala',
])

gflow = library('gflow-'+api,
                src,
                dependencies: [glib, gobject],
                vala_gir: 'gflow-' + api + '.gir',
                install: true)

gflow_inc = include_directories('.')

# TODO: figure out how specify gir as input
custom_target('gflow-typelib',
              command: [g_ir_compiler, '--output', '@OUTPUT@', meson.current_build_dir() + '/gflow-' + api + '.gir'],
              output: 'gflow-' + api + '.typelib',
              depends: gflow,
              install: true,
              install_dir: get_option('libdir') + '/girepository-1.0')

install_data(sources: meson.current_build_dir() + '/gflow-' + api + '.gir',
             install_dir: get_option('datadir') + '/gir-1.0')
