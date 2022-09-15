with import <nixpkgs> { };
mkShell {
  name="gtkflow";
  buildInputs = [
    vala
    meson
    ninja
    pkg-config
    gtk3
    glib
    gobject-introspection
    python
    pythonPackages.pygobject3
  ];
}
