#include <gflow-0.10.h>
#include <gtk/gtk.h>
#include <gtkflow-0.10.h>

GtkFlowNodeView *nv;
static void on_button_clicked();

static void activate(GtkApplication *app, gpointer user_data) {
  GtkWidget *window;

  window = gtk_application_window_new(app);
  gtk_window_set_title(GTK_WINDOW(window), "Window");
  gtk_window_set_default_size(GTK_WINDOW(window), 200, 200);

  GtkWidget *sw = gtk_scrolled_window_new(0, 0);
  nv = gtk_flow_node_view_new();
  GtkWidget *button = gtk_button_new_with_label("Add Node");
  GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);

  gtk_container_add(GTK_CONTAINER(sw), GTK_WIDGET(nv));
  gtk_box_pack_start(GTK_BOX(vbox), GTK_WIDGET(button), 0, 0, 0);
  gtk_box_pack_start(GTK_BOX(vbox), GTK_WIDGET(sw), 1, 1, 1);
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(vbox));

  g_signal_connect(button, "clicked", G_CALLBACK(on_button_clicked), 0);
  gtk_widget_show_all(window);
}

static void on_button_clicked() {
  GFlowSimpleNode *n = gflow_simple_node_new();
  GValue sink_v = G_VALUE_INIT;
  g_value_init(&sink_v, G_TYPE_INT);
  GValue source_v = G_VALUE_INIT;
  g_value_init(&source_v, G_TYPE_INT);
  GFlowSimpleSink *sink = gflow_simple_sink_new(&sink_v);
  GFlowSimpleSource *source = gflow_simple_source_new(&source_v);
  gflow_dock_set_name(GFLOW_DOCK(sink), "sink");
  gflow_dock_set_name(GFLOW_DOCK(source), "source");
  gflow_node_add_source(GFLOW_NODE(n), GFLOW_SOURCE(source), 0);
  gflow_node_add_sink(GFLOW_NODE(n), GFLOW_SINK(sink), 0);
  gflow_node_set_name(GFLOW_NODE(n), "node");
  gtk_flow_node_view_add_node(nv, GFLOW_NODE(n));
}

int main(int argc, char **argv) {
  GtkApplication *app;
  int status;

  app = gtk_application_new("org.gtk.example", G_APPLICATION_FLAGS_NONE);
  g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
  status = g_application_run(G_APPLICATION(app), argc, argv);
  g_object_unref(app);

  return status;
}
