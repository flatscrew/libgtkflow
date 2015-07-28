
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

libgtkflowdevhelpdir=$(datadir)/devhelp/books/gtkflow-$(API_VERSION)
libgtkflowdevhelp_DATA = \
    devhelp/gtkflow/gtkflow-$(API_VERSION)/gtkflow-$(API_VERSION).devhelp2 \
    devhelp/gtkflow/gtkflow-$(API_VERSION)/*.png \
    devhelp/gtkflow/gtkflow-$(API_VERSION)/*.html \
    devhelp/gtkflow/gtkflow-$(API_VERSION)/*.htm \
    devhelp/gtkflow/gtkflow-$(API_VERSION)/*.css \
    devhelp/gtkflow/gtkflow-$(API_VERSION)/*.js

libgflowdevhelpdir=$(datadir)/devhelp/books/gflow-$(API_VERSION)
libgflowdevhelp_DATA = \
    devhelp/gflow/gflow-$(API_VERSION)/gflow-$(API_VERSION).devhelp2 \
    devhelp/gflow/gflow-$(API_VERSION)/*.png \
    devhelp/gflow/gflow-$(API_VERSION)/*.html \
    devhelp/gflow/gflow-$(API_VERSION)/*.htm \
    devhelp/gflow/gflow-$(API_VERSION)/*.css \
    devhelp/gflow/gflow-$(API_VERSION)/*.js

$(libgtkflowdevhelp_DATA): libgtkflow-devhelp

$(libgflowdevhelp_DATA): libgflow-devhelp

libgtkflow-devhelp:
	$(VALADOC) -o devhelp/gtkflow --doclet=devhelp \
    -X $(top_builddir)/libgtkflow/gtkflow.h \
    --vapidir=$(top_srcdir)/libgflow \
    --pkg gflow-0.2 \
    --package-name=gtkflow-$(API_VERSION) \
    $(VALADOC_FLAGS) $(gtkflow_sources)

libgflow-devhelp:
	$(VALADOC) -o devhelp/gflow --doclet=devhelp \
    -X $(top_builddir)/libgflow/gflow.h \
    --package-name=gflow-$(API_VERSION) \
    $(VALADOC_FLAGS) $(gflow_sources)

all: libgtkflow-devhelp libgflow-devhelp

clean-local: clean-local-devhelp
.PHONY: clean-local-devhelp
clean-local-devhelp:
	-rm -rf devhelp
