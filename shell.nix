with import <nixpkgs> { };
mkShell {
  name="gtkflow";
  buildInputs = [
    vala
    meson
    ninja
    pkg-config
    gtk3
    gtk4
    glib
    gobject-introspection
    gdb
    python
    pythonPackages.pygobject3
  ];
}
