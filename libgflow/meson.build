src = files([
    'gflow.vala',
    'gflow-aggregator.vala',
    'gflow-dock.vala',
    'gflow-node.vala',
    'gflow-simple-node.vala',
    'gflow-simple-sink.vala',
    'gflow-simple-source.vala',
    'gflow-sink.vala',
    'gflow-source.vala',
])

gflow_api = '1.0'

gflow = library('gflow-' + gflow_api,
                src,
                dependencies: [glib, gobject],
                vala_gir: 'GFlow-' + gflow_api + '.gir',
                install: get_option('enable_gflow')
                )

gflow_inc = include_directories('.')

# necessary to be able to pass it to g-ir-compiler in other libs
gflow_girdir = meson.current_build_dir()

# TODO: figure out how specify gir as input
custom_target('gflow-typelib',
              command: [g_ir_compiler, '--output', '@OUTPUT@', meson.current_build_dir() + '/GFlow-' + gflow_api + '.gir',
                       '--shared-library', get_option('prefix') + '/' + get_option('libdir') + '/libgflow-'+ gflow_api +'.so'],
              output: 'GFlow-' + gflow_api + '.typelib',
              depends: gflow,
              install: get_option('enable_gflow'),
              install_dir: get_option('libdir') + '/girepository-1.0')

girfilename = meson.current_build_dir() + '/' + 'GFlow-' + gflow_api + '.gir'
run_command('touch', girfilename)
if get_option('enable_gflow')
  install_data(sources: girfilename,
               install_dir: get_option('datadir') + '/gir-1.0')
endif

vapifilename = meson.current_build_dir() + '/' + 'gflow-' + gflow_api + '.vapi'
run_command('touch', vapifilename)
if get_option('enable_gflow')
  install_data(sources: vapifilename,
               install_dir: get_option('datadir') + '/vala/vapi')
endif

headerfilename = meson.current_build_dir () + '/gflow-' + gflow_api + '.h'
run_command('touch', headerfilename)
if get_option('enable_gflow')
  install_headers(headerfilename,
                  subdir: 'gflow-' + gflow_api)
endif

if get_option('enable_gflow')
  install_data(sources: [meson.current_source_dir() + '/gflow-' + gflow_api + '.deps'],
               install_dir: get_option('datadir') + '/vala/vapi')
endif

if get_option('enable_gflow')
  pkgconfig.generate(gflow,
                     subdirs: 'gflow-' + gflow_api,
                     version: gflow_api,
                     name: 'gflow',
                     filebase: 'gflow-' + gflow_api,
                     requires: ['glib-2.0', 'gobject-2.0'],
                     description: 'Flow Node Library')
endif

if get_option('enable_valadoc')
    valadoc = find_program('valadoc')
    gflow_docs = custom_target('gflow_apidocs',
                               input: src,
                               install: get_option('enable_gflow'),
                               # FIXME: Installing to tmp, so the target will be built
                               #        the problem is we cannot access a subfolder of the
                               #        buildtarget via the output parameter.
                               #        Find a nicer solution
                               install_dir: '/tmp',
                               command: [valadoc, '-o', 'libgflow/gflow-' + gflow_api, '--doclet', 'devhelp', '@INPUT@', '--force'],
                               output: 'gflow-' + gflow_api)
    if get_option('enable_gflow')
      install_subdir(meson.current_build_dir() + '/gflow-' + gflow_api + '/gflow-' + gflow_api,
                     install_dir: get_option('datadir') + '/devhelp/books',
                     )
    endif
endif
