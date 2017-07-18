#********************************************************************+
# Copyright 2016 Daniel 'grindhold' Brendle
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
#*********************************************************************

project ('gtkflow', 'vala', 'c', meson_version: '>=0.37.1')
# If you can verify that this project also builds with a lower
# meson version, feel free to change the meson_version kwarg

api = '0.2'

pkgconfig = import('pkgconfig')

glib = dependency('glib-2.0')
gobject = dependency('gobject-2.0')
gtk = dependency('gtk+-3.0', version: '>=3.20.0')
math = meson.get_compiler('c').find_library('m', required: true)

g_ir_compiler = find_program('g-ir-compiler')

subdir('libgflow')
subdir('libgtkflow')
subdir('test')
