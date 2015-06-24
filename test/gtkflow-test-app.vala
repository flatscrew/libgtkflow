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
using Gtk;

public class GtkFlowTest.App : GLib.Object
{
  private int index = -1;
  public delegate bool Test ();
  public Gtk.Window window { get; set; }
  public Gtk.Box action_area { get; set; default = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10); }
  public Gtk.Label result { get; set; }
  public GLib.List<void*> tests = new GLib.List<void*> ();
  public bool @continue { get; set; default = true; }
  public string test_prefix { get; set; default = "/gtkflow"; }
  public bool status { get; set; default = true; }
  public App ()
  {
    window = new Gtk.Window (Gtk.WindowType.TOPLEVEL);
    result = new Gtk.Label ("Running Tests: " + test_prefix);
    result.label = "RUNNING";
    action_area.pack_end (result);
    window.add (action_area);
    window.title = "GtkFlow Unit Tests";
    window.destroy.connect (()=>{
      Gtk.main_quit ();
    });
    add_tests ();
    tests.append ((void*) end_test);
    index = -1;
  }
  public void run ()
  {
    GLib.Idle.add (run_test);
    window.show_all ();
    Gtk.main ();
  }
  public bool run_test ()
  {
    GLib.message ("Running test...");
    end_test ();
    return false;
  }
  public virtual void add_tests ()
  {
    return;
  }
  public bool end_test ()
  {
    if (status == true)
      result.label = "PASS";
    else
      GLib.message ("Test Result: "+result.label);
    return false;
  }
  public static int main (string[] args)
  {
    Gtk.init (ref args);
		var app = new App ();
		app.run ();
		return 0;
	}
}
