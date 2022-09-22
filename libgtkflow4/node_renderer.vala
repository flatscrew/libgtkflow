/********************************************************************
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
*********************************************************************/

namespace GtkFlow {
    /**
     * Representations of libgtkflows internal NodeRenderer-Types
     */
    public enum NodeRendererType {
        DOCKLINE,
        DEFAULT,
        CUSTOM
    }

    /**
     * Errors concerning NodeRenderer
     */
    public errordomain NodeRendererError {
        /**
         * If you pass a invalid value to {@link GtkFlow.NodeView.set_node_renderer}
         * Thats not within {@link GtkFlow.NodeRendererType}
         */
        NOT_A_NODE_RENDERER,
        /**
         * You passed a null value to a function that needs to be passed a
         * {@link GtkFlow.NodeRenderer}-implementation instance
         */
        NO_CUSTOM_NODE_RENDERER,
    }

    /**
     * Implementing this class in your application enables you to represent
     * your {@link GFlow.Node}s in a completely customized manner by entirely
     * drawing them yourself.
     */
    public abstract class NodeRenderer : GLib.Object {
        /**
         * Default value for the spacing between the title and the first dock
         */
        public int title_spacing {get; set; default=15;}
        /**
         * Default value for the spacing between the delete button
         * and the title
         */
        public int delete_btn_size {get; set; default=16;}
        /**
         * Default value for the sizeof the Node's resize handle
         */
        public int resize_handle_size {get; set; default=10;}

        /**
         * This signal is triggered whenever the size of the node changes
         */
        public signal void size_changed();
        /**
         * Trigger this signal in implementations to tell the Node
         * to render the given childwidget
         */
        public signal void child_redraw(Gtk.Widget child);

        protected NodeRenderer () {}

        /**
         * Implementations should draw the graphical representation of
         * the node on the given {@link Cairo.Context}
         */
        public abstract void draw_node(Gtk.Widget w,
                                       Cairo.Context cr,
                                       Gtk.Allocation alloc,
                                       List<DockRenderer> dock_renderers,
                                       List<Gtk.Widget> children,
                                       int border_width,
                                       NodeProperties node_properties,
                                       Gtk.Widget? title=null);
        /**
         * Implementations should calculate whether there is a dock
         * on this node specified by the {@link Point} p . If so,
         * return the dock, otherwise return null
         */
        public abstract GFlow.Dock? get_dock_on_position(Point p,
                                                    List<DockRenderer> dock_renderers,
                                                    uint border_width,
                                                    Gtk.Allocation alloc,
                                                    Gtk.Widget? title=null);
        /**
         * Implementations should calculate the position of the given
         * dock on the canvas and write it into the parameters x and y.
         * If everything went well, return true. If there is no such dock,
         * return false.
         */
        public abstract bool get_dock_position(GFlow.Dock d,
                                                    List<DockRenderer> dock_renderers,
                                                    int border_width,
                                                    Gtk.Allocation alloc,
                                                    out int x,
                                                    out int y,
                                                    Gtk.Widget? title=null);
        /**
         * Implementations should return true if the given position is
         * on the node's closebutton.
         */
        public abstract bool is_on_closebutton(Point p,
                                               Gtk.Allocation alloc,
                                               uint border_width);
        /**
         * Implementations should return true if the given position is
         * on the node's resize handle.
         */
        public abstract bool is_on_resize_handle(Point p,
                                               Gtk.Allocation alloc,
                                               uint border_width);
        /**
         * Implementations should return the minimum width that this
         * node needs in order to be correctly rendered.
         */
        public abstract uint get_min_width(List<DockRenderer> dock_renderers,
                                           List<Gtk.Widget> children,
                                           int border_width,
                                           Gtk.Widget? title=null);
        /**
         * Implementations should return the minimum height that this
         * node needs in order to be correctly rendered.
         */
        public abstract uint get_min_height(List<DockRenderer> dock_renderers,
                                           List<Gtk.Widget> children,
                                           int border_width,
                                           Gtk.Widget? title=null);
        /**
         * If this NodeRenderer-implementation renderes text, like the
         * nodes name, this method is executed everytime the namestring of
         * the {@link GFlow.Node} changes.
         */
        public abstract void update_name_layout(string name);
    }
}
