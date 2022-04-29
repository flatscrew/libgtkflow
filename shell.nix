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
    python38
    python38Packages.pygobject3
  ];
}
