/* -*- Mode: vala; indent-tabs-mode: nil; c-basic-offset: 2; tab-width: 2 -*-  */
/* GFlowTest
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

public class GFlowTest.Source : GFlow.SimpleSource
{
  public Source () {
    base.with_type (typeof(bool));
  }
}

public class GFlowTest.SourceTest
{
  public static void add_tests ()
  {
    Test.add_func ("/gflow/source", 
    () => {
      var src = new GFlow.SimpleSource.with_type (typeof(int));
      try {
          src.set_value(0);
      } catch {
          assert_not_reached();
      }
      assert (!src.is_linked ());
    });
    Test.add_func ("/gflow/source/link", 
    () => {
      var src = new GFlow.SimpleSource.with_type (typeof(int));
      try{
          src.set_value(0);
      } catch {
          assert_not_reached();
      }
      var s = new GFlow.SimpleSink.with_type (typeof(bool));
      var s1 = new GFlow.SimpleSink.with_type (typeof(int));
      var s2 = new GFlow.SimpleSink.with_type (typeof(int));
      assert (!src.is_linked ());
      bool fail = true;
      try { src.link (s); } catch { fail = false; }
      if (fail) assert_not_reached ();
      try {
        assert (!s1.is_linked ());
        fail = true;
        s1.linked.connect (()=>{
          fail = false;
        });
        src.link (s1);
        if (fail)  assert_not_reached ();
        fail = true;
        s2.linked.connect (()=>{
          fail = false;
        });
        src.link (s2);
        if (fail)  assert_not_reached ();
        try {
            src.set_value(20);
        } catch {
            assert_not_reached();
        }

        //  assert (((int) s1.val.nth_data(0)) == 20);
        //  assert (((int) s2.val.nth_data(0)) == 20);
      } catch { assert_not_reached (); }
    });
    Test.add_func ("/gflow/source/derived", 
    () => {
      var src = new GFlowTest.Source ();
      assert (!src.is_linked ());
    });
  }
}
