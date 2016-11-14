#********************************************************************+
# Copyright 2016 Daniel 'grindhold' Brendle
#
# This file is part of libhttpseverywhere.
#
# libhttpseverywhere is free software: you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later
# version.
#
# libhttpseverywhere is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with libhttpseverywhere.
# If not, see http://www.gnu.org/licenses/.
#*********************************************************************

project ('gtkflow', 'vala', 'c')

api = '0.2'

pkgconfig = import('pkgconfig')

glib = dependency('glib-2.0')
gobject = dependency('gobject-2.0')
gtk = dependency('gtk+-3.0')

gflow_lib_source = [
    'libgflow/gflow-dock.vala',
    'libgflow/gflow-node.vala',
    'libgflow/gflow-simple-node.vala',
    'libgflow/gflow-simple-sink.vala',
    'libgflow/gflow-simple-source.vala',
    'libgflow/gflow-sink.vala',
    'libgflow/gflow-source.vala',
]

gtkflow_lib_source = [
    'libgtkflow/dock_renderer.vala',
    'libgtkflow/node_renderer.vala',
    'libgtkflow/node.vala',
    'libgtkflow/nodeview.vala',
]

gflow_lib = library('gflow-'+api, gflow_lib_source,
                    dependencies: [glib, gobject],
                    vala_args: ['--gir=../GFlow-'+api+'.gir', '-H', 'gflow-'+api+'/gflow.h'],
                    install: true)

#TODO: gtkflow must find gflow headers
gtkflow_lib = library('gtkflow-'+api, gtkflow_lib_source,
                    dependencies: [glib, gobject, gtk],
                    vala_args: ['--gir=../GtkFlow-'+api+'.gir', '-H', 'gtkflow-'+api+'/gtkflow.h',
                                '-X','-Igflow-0.2'],
                    link_with: gflow_lib,
                    install: true)

#TODO: testing

g_ir_compiler = find_program('g-ir-compiler')
#TODO: girfiles

valadoc = find_program('valadoc')
#TODO: documentation

#TODO: pkgconfig

#TODO: manual installations
