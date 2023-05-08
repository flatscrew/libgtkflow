{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  outputs = { self, nixpkgs } : 
  rec
  {
    system = "x86_64-linux";
    packages.x86_64-linux.libgtkflow3 = 
    with import nixpkgs {inherit system;};

    stdenv.mkDerivation rec {
      pname = "libgtkflow3";
      version = "1.0.6";

      outputs = [ "out" "dev" "devdoc" ];
      outputBin = "devdoc"; # demo app

      src = ./.;

      nativeBuildInputs = [
        vala
        meson
        ninja
        pkg-config
        gobject-introspection
      ];

      buildInputs = [
        gtk3
        glib
        self.${system}libgflow
      ];

      postFixup = ''
        # Cannot be in postInstall, otherwise _multioutDocs hook in preFixup will move right back.
        moveToOutput "share/doc" "$devdoc"
      '';

      mesonFlags = [
        "-Denable_valadoc=true"
        "-Denable_gtk4=false"
        "-Denable_gflow=false"
      ];

      postPatch = ''
        rm -r libgflow
      '';

      meta = with lib; {
        description = "Flow graph widget for GTK 3";
        homepage = "https://notabug.org/grindhold/libgtkflow";
        maintainers = with maintainers; [ grindhold ];
        license = licenses.lgpl3Plus;
        platforms = platforms.unix;
      };
    };

    packages.x86_64-linux.libgflow = 
    with import nixpkgs {inherit system;};

    stdenv.mkDerivation rec {
      pname = "libgflow";
      version = "1.0.4";

      outputs = [ "out" "dev" "devdoc" ];
      outputBin = "devdoc"; # demo app

      src = ./.;

      nativeBuildInputs = [
        vala
        meson
        ninja
        pkg-config
        gobject-introspection
      ];

      buildInputs = [
        glib
      ];

      postFixup = ''
        # Cannot be in postInstall, otherwise _multioutDocs hook in preFixup will move right back.
        moveToOutput "share/doc" "$devdoc"
      '';

      mesonFlags = [
        "-Denable_valadoc=false"
        "-Denable_gtk4=false"
        "-Denable_gflow=true"
      ];

      meta = with lib; {
        description = "Abstract flow graph logic for GLib";
        homepage = "https://notabug.org/grindhold/libgtkflow";
        maintainers = with maintainers; [ grindhold ];
        license = licenses.lgpl3Plus;
        platforms = platforms.unix;
      };
    };

    devShell.x86_64-linux =
      with import nixpkgs {inherit system;};
      mkShell {
        name = "flohmarkt devshell";
        buildInputs = [
          vala
          meson
          ninja
          pkg-config
          gobject-introspection
          gtk3
          glib
          self.${system}.libgflow
        ];
    };
  };
}
