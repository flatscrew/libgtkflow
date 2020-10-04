GtkFlow
=======

Here you see libgtkflow, a universal library for drawing flow graphs with
Gtk+ 3.

![SameLineDocks](./screenshots/sameline.png)

Sinks and Sources may now appear on the same line

![GtkFlowMultisink](./screenshots/multisink.png)

We now have Sinks that can receive data from multiple sources!

![GtkFlowColor](./screenshots/gtk3-20.png)

A more recent screenshot showing off libgtkflow with Gtk > 3.20. It looks
a bit clearer.

![LibGtkFlow](./screenshots/broadway.png)

This is libgtkflow running inside firefox via broadway ↑

![GtkFlowWindows](./screenshots/windows.png)

GtkFlow runs unter that strange M$-operating-system, too ↑

![GtkFlowRes](./screenshots/resize.png)

The newest stuff in libgtkflow's development ↑
Nodes can be deleted by clicking the X-button in the upper right corner.
Nodes are resizable by drag-n-dropping the lower right corner. The types of the docks can be printed along with their names

![GtkFlowEvopop](./screenshots/evopop.png)

This is a screenshot of libgtkflow rendered with the evopop Gtk3 theme ↑

![GtkFlow](./screenshots/first_shot.png)

This here is the included advanced calculator demo application ↑

Flow graphs are a possibility to let your user model flows of data from, through
and into several stations.

Motivation
----------

I love Flowgraphs in other programs and i want to have them in my favourite
UI-toolkit Gtk. I ran into some programs which implemented similar functionality
but they all didn't feel or even look very Gtk-like/GNOMEy.

Possible Usages
---------------

Specific:

  * Writing an UI for [GStreamer](http://gstreamer.org)
  * Writing an UI for [Beehive](https://github.com/muesli/beehive)
  * Replacement for the UI in [Gnuradio](http://gnuradio.org)
  * Matching monitors / inputs / outputs in [Pavucontrol](http://freedesktop.org/software/pulseaudio/pavucontrol/) this is actually being worked on → [pulse-flow](https://github.com/benwaffle/pulse-flow)
  * Writing an UI for [GEGL](http://gegl.org)

Unspecific:

  * Video Compositing (maybe [PiTiVi](http://www.pitivi.org))
  * Visualizing dependencies of objects (e.g. debian packages in apt)

  * … and whatever you can think up.

Stability
-------------

Core features are implemented and work quite well.
API undergoes additions from time to time. The project is not at 1.0 yet
as such, API can break but we don't expect fundamental breaking changes
to core features anytime soon. If we introduce additional features, we
try to offer them as additional API methods rather than changing existing
ones.

Building
--------

Make sure you get the following Dependencies:

  * libgtk-3-dev
  * gobject-introspection (libgirepository1.0-dev)
  * meson
  * vala
  * (valadoc)

Then do the following:

```
$ git clone https://github.com/grindhold/libgtkflow
$ cd libgtkflow
$ mkdir build
$ cd build
$ meson ..
$ ninja
# sudo ninja install
```

A user of the library (thx @gavr) reported:

"I have no idea why, but on OpenSUSE Tumbleweed pkgbuild will only be able to find gtkFlow if you build it like that:"
```
meson _build --buildtype=release --prefix=/usr
```

Examples
--------

libgtkflow supports GObject-Introspection which means you can consume it in various
popular languages including but not limited to: Python, Perl, Lua, JS, PHP.
I compiled some examples on how to program against the library in Python in the examples-folder.

Feel free to add examples for your favorite language.

Note: If you installed the library in /usr/local, you have to export the following
environment variables for the examples to work:

```
export LD_LIBRARY_PATH=/usr/local/lib/x86_64-linux-gnu
export GI_TYPELIB_PATH=/usr/local/lib/x86_64-linux-gnu/girepository-1.0/
```

Please be aware that on other architectures than amd64 you will have to change the
multiarch string ```x86_64-linux-gnu``` to something else that makes sense on your
machine.
