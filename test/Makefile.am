include $(top_srcdir)/gtester.mk

NULL =

### General compilation flags
AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(datadir)"\"

AM_CFLAGS = \
	-g \
	$(GLIB_CFLAGS) \
	$(GTK_CFLAGS) \
	-I$(top_builddir)/. \
	-I$(top_builddir)/libgtkflow \
	-DTEST_DIR=\"$(builddir)\" \
	$(NULL)


noinst_PROGRAMS = $(TEST_PROGS)

TEST_PROGS += gflow_test

sources = \
	gflow-test.vala \
	tests-config.vala \
	gflow-sink-test.vala \
	gflow-source-test.vala \
	gflow-dock-test.vala \
	gflow-node-test.vala \
	gtkflow-test-app-class.vala \
	gtkflow-node-test.vala \
	$(NULL)

$(sources:.vala=.c): $(sources)
	$(VALAC) $(AM_VALAFLAGS) $^

gflow_test_SOURCES = $(sources:.vala=.c)

AM_VALAFLAGS = \
	--vapidir=$(top_builddir)/libgflow \
	--pkg gflow-0.2 \
	--vapidir=$(top_builddir)/libgtkflow \
	--pkg gtkflow-0.2 \
	--pkg gtk+-3.0 \
	-C \
	-g \
	-X -DTEST_DIR=$(top_srcdir)/test \
	$(NULL)

if DEBUG
AM_VALAFLAGS+= -D DEBUG
endif

gflow_test_LDADD = \
	$(AM_LDADD) \
	$(GLIB_LIBS) \
	$(GTK_LIBS) \
	../libgflow/libgflow-0.2.la \
	../libgtkflow/libgtkflow-0.2.la \
	$(NULL)

gflow_test_LDFLAGS = $(AM_LDFLAGS)


CLEANFILES = \
	$(sources:.vala=.c) \
	gtkflow_test_vala.stamp-t \
	gflow_test

DISTCLEANFILES = 

EXTRA_DIST += \
	$(sources) \
	$(NULL)

