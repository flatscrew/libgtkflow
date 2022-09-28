#********************************************************************
# Copyright 2014-2022 Daniel 'grindhold' Brendle
#
# This file is part of libgtkflow.
#
# libgtkflow is free software: you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later
# version.
#
# libgtkflow is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with libgtkflow.
# If not, see http://www.gnu.org/licenses/.
#********************************************************************

src = files([
    'nodeview.vala',
    'node.vala',
    'dock.vala',
])

gtkflow4 = library('gtkflow4-' + api,
                  src,
                  dependencies: [glib, gobject, gtk4, math],
                  link_with: gflow,
                  include_directories: gflow_inc,
                  vala_gir: 'GtkFlow4-' + api + '.gir',
                  install: true)

gtkflow4_inc = include_directories('.')

custom_target('gtkflow4-typelib',
              command: [g_ir_compiler, '--output', '@OUTPUT@', meson.current_build_dir() + '/GtkFlow4-' + api + '.gir',
                       '--includedir', gflow_girdir,
                       '--shared-library', get_option('prefix') + '/' + get_option('libdir') + '/libgtkflow4-'+ api +'.so'],
              output: 'GtkFlow4-' + api + '.typelib',
              depends: gtkflow4,
              install: true,
              install_dir: get_option('libdir') + '/girepository-1.0')

girfilename4 = meson.current_build_dir() + '/GtkFlow4-' + api + '.gir'
run_command('touch', girfilename4)
install_data(sources: girfilename4,
             install_dir: get_option('datadir') + '/gir-1.0')

vapifilename4 = meson.current_build_dir() + '/gtkflow4-' + api + '.vapi'
run_command('touch', vapifilename4)
install_data(sources: vapifilename4,
             install_dir: get_option('datadir') + '/vala/vapi')

headerfilename4 = meson.current_build_dir () + '/gtkflow4-' + api + '.h'
run_command('touch', headerfilename4)
install_headers(headerfilename4,
                subdir: 'gtkflow4-' + api)
install_data(sources: [meson.current_source_dir() + '/gtkflow4-' + api + '.deps'],
             install_dir: get_option('datadir') + '/vala/vapi')

pkgconfig.generate(libraries: [gflow, gtkflow4],
                   subdirs: 'gtkflow4-' + api,
                   version: api,
                   name: 'gtkflow4',
                   filebase: 'gtkflow4-' + api,
                   requires: ['glib-2.0', 'gobject-2.0', 'gflow-' + api],
                   description: 'A library to create flowgraphs in GTK+')

if get_option('enable_valadoc')
    valadoc = find_program('valadoc')
    gtkflow4_docs = custom_target('gtkflow_apidocs',
                                 depends: gflow,
                                 input: src,
                                 install: true,
                                 # FIXME: Installing to tmp, so the target will be built
                                 #        the problem is we cannot access a subfolder of the
                                 #        buildtarget via the output parameter.
                                 #        Find a nicer solution
                                 install_dir: '/tmp',
                                 command: [valadoc, '-o', 'libgtkflow/gtkflow4-' + api, '--doclet', 'devhelp', '@INPUT@',
                                 '--pkg', 'gtk4', '--vapidir=' + meson.current_build_dir() + '/../libgflow/', '--pkg', 'gflow-' + api,
                                 '--force'],
                                 output: 'gtkflow4-'+ api)
    install_subdir(meson.current_build_dir() + '/gtkflow4-' + api + '/gtkflow4-' + api,
                   install_dir: get_option('datadir') + '/devhelp/books',
                   )
endif
