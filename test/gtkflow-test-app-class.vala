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

public abstract class GtkFlowTest.TestApp : GLib.Object
{
  public delegate bool Test ();
  public Gtk.Window window { get; set; }
  public Gtk.Box action_area { get; set; default = new Gtk.Box (Gtk.Orientation.VERTICAL, 10); }
  public Gtk.Label result { get; set; }
  public Gtk.Button brun;
  public GLib.List<void*> tests = new GLib.List<void*> ();
  public bool @continue { get; set; default = true; }
  public string test_prefix { get; set; default = "/gtkflow"; }
  public bool status { get; set; default = true; }
  public TestApp ()
  {
    window = new Gtk.Window (Gtk.WindowType.TOPLEVEL);
    result = new Gtk.Label ("Running Tests: " + test_prefix);
    result.label = "RUNNING";
    action_area.pack_end (result);
    brun = new Gtk.Button ();
    brun.label = "Run";
    action_area.pack_end (brun);
    window.add (action_area);
    window.title = "GtkFlow Unit Tests";
    window.destroy.connect (()=>{
      Gtk.main_quit ();
    });
    brun.clicked.connect (()=>{
      if (execute () != 0)
        status = false;
      else
        status = true;
    });
  }
  public void run ()
  {
    window.show_all ();
    Gtk.main ();
  }
  public abstract int execute ();
  public bool end_test ()
  {
    if (status == true)
      result.label = "PASS";
    else
      GLib.message ("Test Result: "+result.label);
    return false;
  }
}
