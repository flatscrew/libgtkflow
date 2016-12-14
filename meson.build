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
math = meson.get_compiler('c').find_library('m', required: true)

g_ir_compiler = find_program('g-ir-compiler')

subdir('libgflow')
subdir('libgtkflow')
subdir('test')
