/**
 * Code Taken from the foreign drawing demo of gtk
 * <gtk-git-repo>/demos/gtk-demo/foreigndrawing.c
 * License: LGPL
 */

#include <gtk/gtk.h>
#include <string.h>
#include <stdio.h>

void append_element (GtkWidgetPath *path, const char *selector);

void
query_size (GtkStyleContext *context,
            gint            *width,
            gint            *height)
{
  GtkBorder margin, border, padding;
  int min_width, min_height;

  gtk_style_context_get_margin (context, gtk_style_context_get_state (context), &margin);
  gtk_style_context_get_border (context, gtk_style_context_get_state (context), &border);
  gtk_style_context_get_padding (context, gtk_style_context_get_state (context), &padding);

  gtk_style_context_get (context, gtk_style_context_get_state (context),
                         "min-width", &min_width,
                         "min-height", &min_height,
                         NULL);

  min_width += margin.left + margin.right + border.left + border.right + padding.left + padding.right;
  min_height += margin.top + margin.bottom + border.top + border.bottom + padding.top + padding.bottom;

  if (width)
    *width = MAX (*width, min_width);
  if (height)
    *height = MAX (*height, min_height);
}

static GtkStyleContext *
create_context_for_path (GtkWidgetPath   *path,
                         GtkStyleContext *parent)
{
  GtkStyleContext *context;

  context = gtk_style_context_new ();
  gtk_style_context_set_path (context, path);
  gtk_style_context_set_parent (context, parent);
  /* Unfortunately, we have to explicitly set the state again here
   * for it to take effect
   */
  gtk_style_context_set_state (context, gtk_widget_path_iter_get_state (path, -1));
  gtk_widget_path_unref (path);

  return context;
}

GtkStyleContext *
get_style (GtkStyleContext *parent,
           const char      *selector)
{
  GtkWidgetPath *path;

  if (parent)
    path = gtk_widget_path_copy (gtk_style_context_get_path (parent));
  else
    path = gtk_widget_path_new ();

  append_element (path, selector);

  return create_context_for_path (path, parent);
}

static void
draw_style_common (GtkStyleContext *context,
                   cairo_t         *cr,
                   gint             x,
                   gint             y,
                   gint             width,
                   gint             height,
                   gint            *contents_x,
                   gint            *contents_y,
                   gint            *contents_width,
                   gint            *contents_height)
{
  GtkBorder margin, border, padding;
  int min_width, min_height;

  gtk_style_context_get_margin (context, gtk_style_context_get_state (context), &margin);
  gtk_style_context_get_border (context, gtk_style_context_get_state (context), &border);
  gtk_style_context_get_padding (context, gtk_style_context_get_state (context), &padding);

  gtk_style_context_get (context, gtk_style_context_get_state (context),
                         "min-width", &min_width,
                         "min-height", &min_height,
                         NULL);
  x += margin.left;
  y += margin.top;
  width -= margin.left + margin.right;
  height -= margin.top + margin.bottom;

  width = MAX (width, min_width);
  height = MAX (height, min_height);

  gtk_render_background (context, cr, x, y, width, height);
  gtk_render_frame (context, cr, x, y, width, height);

  if (contents_x)
    *contents_x = x + border.left + padding.left;
  if (contents_y)
    *contents_y = y + border.top + padding.top;
  if (contents_width)
    *contents_width = width - border.left - border.right - padding.left - padding.right;
  if (contents_height)
    *contents_height = height - border.top - border.bottom - padding.top - padding.bottom;
}

void
gtk_flow_draw_radio (GtkWidget     *widget,
            cairo_t       *cr,
            gint           x,
            gint           y,
            GtkStateFlags  state,
            gint          *width,
            gint          *height)
{
  GtkStyleContext *button_context;
  GtkStyleContext *check_context;
  gint contents_x, contents_y, contents_width, contents_height;

  /* This information is taken from the GtkRadioButton docs, see "CSS nodes" */
  button_context = get_style (NULL, "radiobutton");
  check_context = get_style (button_context, "radio");

  gtk_style_context_set_state (check_context, state);

  *width = *height = 0;
  query_size (button_context, width, height);
  query_size (check_context, width, height);

  draw_style_common (button_context, cr, x, y, *width, *height, NULL, NULL, NULL, NULL);
  draw_style_common (check_context, cr, x, y, *width, *height,
                     &contents_x, &contents_y, &contents_width, &contents_height);
  gtk_render_check (check_context, cr, contents_x, contents_y, contents_width, contents_height);

  g_object_unref (check_context);
  g_object_unref (button_context);
}

void
append_element (GtkWidgetPath *path,
                const char    *selector)
{
  // >>>> gtk-3.18 fix
  /*
  static const struct {
    const char    *name;
    GtkStateFlags  state_flag;
  } pseudo_classes[] = {
    { "active",        GTK_STATE_FLAG_ACTIVE },
    { "hover",         GTK_STATE_FLAG_PRELIGHT },
    { "selected",      GTK_STATE_FLAG_SELECTED },
    { "disabled",      GTK_STATE_FLAG_INSENSITIVE },
    { "indeterminate", GTK_STATE_FLAG_INCONSISTENT },
    { "focus",         GTK_STATE_FLAG_FOCUSED },
    { "backdrop",      GTK_STATE_FLAG_BACKDROP },
    { "dir(ltr)",      GTK_STATE_FLAG_DIR_LTR },
    { "dir(rtl)",      GTK_STATE_FLAG_DIR_RTL },
    { "link",          GTK_STATE_FLAG_LINK },
    { "visited",       GTK_STATE_FLAG_VISITED },
    { "checked",       GTK_STATE_FLAG_CHECKED },
    { "drop(active)",  GTK_STATE_FLAG_ACTIVE } // changed for compatibility with gtk 3.18
  };
  const char *next;
  char *name;
  char type;
  guint i;

  next = strpbrk (selector, "#.:");
  if (next == NULL)
    next = selector + strlen (selector);

  name = g_strndup (selector, next - selector);
  if (g_ascii_isupper (selector[0]))
    {
      GType gtype;
      gtype = g_type_from_name (name);
      if (gtype == G_TYPE_INVALID)
        {
          g_critical ("Unknown type name `%s'", name);
          g_free (name);
          return;
        }
      gtk_widget_path_append_type (path, gtype);
    }
  else
    {
      // Omit type, we're using name
      gtk_widget_path_append_type (path, G_TYPE_NONE);
      gtk_widget_path_iter_set_object_name (path, -1, name);
    }
  g_free (name);

  while (*next != '\0')
    {
      type = *next;
      selector = next + 1;
      next = strpbrk (selector, "#.:");
      if (next == NULL)
        next = selector + strlen (selector);
      name = g_strndup (selector, next - selector);

      switch (type)
        {
        case '#':
          gtk_widget_path_iter_set_name (path, -1, name);
          break;

        case '.':
          gtk_widget_path_iter_add_class (path, -1, name);
          break;

        case ':':
          for (i = 0; i < G_N_ELEMENTS (pseudo_classes); i++)
            {
              if (g_str_equal (pseudo_classes[i].name, name))
                {
                  gtk_widget_path_iter_set_state (path,
                                                  -1,
                                                  gtk_widget_path_iter_get_state (path, -1)
                                                  | pseudo_classes[i].state_flag);
                  break;
                }
            }
          if (i == G_N_ELEMENTS (pseudo_classes))
            g_critical ("Unknown pseudo-class :%s", name);
          break;

        default:
          g_assert_not_reached ();
          break;
        }

      g_free (name);
    }
  */
  // <<<< gtk-3.18 fix
}
