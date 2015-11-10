
CLEANFILES=

VALADOC_FLAGS = \
    --driver $(VALAC_VERSION) \
    --force \
    --package-version=$(PACKAGE_VERSION) \
    --pkg glib-2.0 \
    --pkg gio-2.0 \
    --pkg gtk+-3.0 \
    --vapidir=$(top_srcdir)/libgtkflow

gtkflow_sources= \
    $(top_srcdir)/libgtkflow/*.vala

gflow_sources= \
    $(top_srcdir)/libgflow/*.vala

libgtkflowgtkdocdir=$(datadir)/gtk-doc/html/gtkflow
libgtkflowgtkdoc_DATA= \
    gtk-doc/gtkflow/*.txt \
    gtk-doc/gtkflow/*.xml \
    gtk-doc/gtkflow/xml/*.xml \
    gtk-doc/gtkflow/xml/*.top \
    gtk-doc/gtkflow/xml/*.bottom \
    gtk-doc/gtkflow/*.types \
    gtk-doc/gtkflow/sgml.stamp

libgflowgtkdocdir=$(datadir)/gtk-doc/html/gflow
libgflowgtkdoc_DATA= \
    gtk-doc/gflow/*.txt \
    gtk-doc/gflow/*.xml \
    gtk-doc/gflow/xml/*.xml \
    gtk-doc/gflow/xml/*.top \
    gtk-doc/gflow/xml/*.bottom \
    gtk-doc/gflow/*.types \
    gtk-doc/gflow/sgml.stamp

$(libgtkflowgtkdoc_DATA): libgtkflow-gtk-doc

$(libgflowgtkdoc_DATA): libgflow-gtk-doc

libgtkflow-gtk-doc:
	$(VALADOC) -o gtk-doc/gtkflow --doclet=gtkdoc \
    -X $(top_builddir)/libgtkflow/gtkflow.h \
    --vapidir=$(top_srcdir)/libgflow \
    --pkg gflow-0.2 \
    --package-name=gtkflow-$(API_VERSION) \
    $(VALADOC_FLAGS) $(gtkflow_sources)

libgflow-gtk-doc:
	$(VALADOC) -o gtk-doc/gflow --doclet=gtkdoc \
    -X $(top_builddir)/libgflow/gflow.h \
    --package-name=gflow-$(API_VERSION) \
    $(VALADOC_FLAGS) $(gflow_sources)

all: libgtkflow-gtk-doc libgflow-gtk-doc

clean-local: clean-local-gtk-doc
.PHONY: clean-local-gtk-doc
clean-local-gtk-doc:
	-rm -rf gtk-doc
