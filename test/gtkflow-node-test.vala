/* -*- Mode: vala; indent-tabs-mode: nil; c-basic-offset: 2; tab-width: 2 -*-  */
/* GtkFlowTest
 *
 * Copyright (C) 2015 Daniel Espinosa <esodan@gmail.com>
 *
 * librescl is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * librescl is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using GFlow;
using GtkFlow;

public class GtkFlowTest.GuiNodeTest : GtkFlowTest.TestApp
{
  public GuiNodeTest ()
  {
    base ();
    test_prefix = "/gtkflow/node";
  }
  public override int execute ()
  {
    try {
      GLib.message ("Executing Tests...");
      var nview = new GtkFlow.NodeView ();
      this.action_area.pack_end (nview);
      var s1 = new GFlow.SimpleSink.with_type (typeof(bool));
      var src1 = new GFlow.SimpleSource.with_type (typeof(bool));
      try {
          src1.set_value(true);
      } catch {
          assert_not_reached();
      }
      var n1 = new GFlow.SimpleNode ();
      n1.add_sink (s1);
      var n2 = new GFlow.SimpleNode ();
      n2.add_source (src1);
      nview.add_node (n1);
      nview.add_node (n2);
      window.destroy ();
    } catch (Error e) {
      GLib.message ("ERROR: "+e.message);
      assert_not_reached ();
    }
    return 0;
  }
}

public class GtkFlowTest.NodeTest
{
  public static void add_tests ()
  {
    Test.add_func ("/gtkflow/node", 
    () => {
      var app = new GuiNodeTest ();
      app.run ();
      assert (app.status);
    });
  }
}
