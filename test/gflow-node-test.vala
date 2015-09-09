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

public class GFlowTest.NodeTest {
    public static void add_tests () {
        Test.add_func ("/gflow/node/sink",
        () => {
            try {
                Value initial = Value(typeof(int));
                initial.set_int (1);
                var s = new GFlow.SimpleSink (initial);
                var n = new GFlow.SimpleNode ();
                assert (n.has_sink(s) == false);
                n.add_sink(s);
                assert (n.has_sink(s) == true);
                n.remove_sink(s);
                assert (n.has_sink(s) == false);
            } catch (GFlow.NodeError e) {
                assert (false);
            }
        });
        Test.add_func ("/gflow/node/source",
        () => {
            try {
                Value initial = Value(typeof(int));
                initial.set_int (1);
                var s = new GFlow.SimpleSource (initial);
                var n = new GFlow.SimpleNode ();
                assert (n.has_source(s) == false);
                n.add_source(s);
                assert (n.has_source(s) == true);
                n.remove_source(s);
                assert (n.has_source(s) == false);
            } catch (GFlow.NodeError e) {
                assert (false);
            }
        });
        Test.add_func ("/gflow/node/dock",
        () => {
            try {
                Value si_initial = Value(typeof(int));
                si_initial.set_int (1);
                var si = new GFlow.SimpleSink (si_initial);
                Value so_initial = Value(typeof(int));
                so_initial.set_int (1);
                var so = new GFlow.SimpleSource (so_initial);

                var n = new GFlow.SimpleNode ();
                assert (n.has_dock(si) == false);
                assert (n.has_dock(so) == false);
                n.add_source(so);
                n.add_sink(si);
                assert (n.has_dock(si) == true);
                assert (n.has_dock(so) == true);
                n.remove_source(so);
                n.remove_sink(si);
                assert (n.has_dock(si) == false);
                assert (n.has_dock(so) == false);
            } catch (GFlow.NodeError e) {
                assert (false);
            }
        });
        Test.add_func ("/gflow/node/get_dock",
        () => {
            try {
                Value si_initial = Value(typeof(int));
                si_initial.set_int (1);
                var si = new GFlow.SimpleSink (si_initial);
                si.name = "foo";
                Value so_initial = Value(typeof(int));
                so_initial.set_int (1);
                var so = new GFlow.SimpleSource (so_initial);
                so.name = "bar";
                var n = new GFlow.SimpleNode();
                assert(n.get_dock("foo") == null);
                assert(n.get_dock("bar") == null);
                n.add_sink(si);
                n.add_source(so);
                assert(n.get_dock("foo") == si);
                assert(n.get_dock("bar") == so);
                n.remove_source(so);
                n.remove_sink(si);
                assert(n.get_dock("foo") == null);
                assert(n.get_dock("bar") == null);
            } catch (GFlow.NodeError e) {
                assert (false);
            }
        });
    }
}
