src = files([
    'aggregator.vala'
])

gflowpatterns_inc = include_directories('.')

gee = dependency('gee-0.8')

gflowpatterns = library('gflowpatterns-' + api,
                  src,
                  dependencies: [glib, gobject, gee],
                  link_with: gflow,
                  include_directories: gflow_inc,
                  vala_gir: 'GFlowPatterns-' + api + '.gir',
                  install: true)

# TODO: figure out how specify gir as input
custom_target('gflowpatterns-typelib',
              command: [g_ir_compiler, '--output', '@OUTPUT@', meson.current_build_dir() + '/GFlowPatterns-' + api + '.gir',
                       '--shared-library', get_option('prefix') + '/' + get_option('libdir') + '/libgflowpatterns-'+ api +'.so'],
              output: 'GFlowPatterns-' + api + '.typelib',
              depends: gflowpatterns,
              install: true,
              install_dir: get_option('libdir') + '/girepository-1.0')

girfilename = meson.current_build_dir() + '/' + 'GFlowPatterns-' + api + '.gir'
run_command('touch', girfilename)
install_data(sources: girfilename,
             install_dir: get_option('datadir') + '/gir-1.0')

vapifilename = meson.current_build_dir() + '/' + 'gflowpatterns-' + api + '.vapi'
run_command('touch', vapifilename)
install_data(sources: vapifilename,
             install_dir: get_option('datadir') + '/vala/vapi')

headerfilename = meson.current_build_dir () + '/gflowpatterns-' + api + '.h'
run_command('touch', headerfilename)
install_headers(headerfilename,
                subdir: 'gflowpatterns-' + api)

install_data(sources: [meson.current_source_dir() + '/gflowpatterns-' + api + '.deps'],
             install_dir: get_option('datadir') + '/vala/vapi')

pkgconfig.generate(gflowpatterns,
                   subdirs: 'gflowpatterns-' + api,
                   version: api,
                   name: 'gflowpatterns',
                   filebase: 'gflowpatterns-' + api,
                   requires: ['glib-2.0', 'gobject-2.0'],
                   description: 'Flow Node Library Patterns')