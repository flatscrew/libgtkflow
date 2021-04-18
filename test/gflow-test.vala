/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 2 -*- */
/********************************************************************
# Copyright 2014-2021 Daniel 'grindhold' Brendle, 2015 Daniel Espinosa <esodan@gmail.com>
#
# This file is part of libgflow.
#
# libgflow is free software: you can redistribute it and/or
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
*********************************************************************/

using GFlow;

class GFlowTest.Main {
	public static int main (string[] args) {
		Test.init (ref args);
		Gtk.init (ref args);
		SourceTest.add_tests ();
		SinkTest.add_tests ();
		DockTest.add_tests ();
		NodeTest.add_tests ();
		GtkFlowTest.NodeTest.add_tests ();
		GFlowTest.AggregatorTest.add_tests() ;
		Test.run ();
		return 0;
	}

}
