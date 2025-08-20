{
  description = "Thunar file manager built from GitHub mirror source";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.stdenv.mkDerivation rec {
          pname = "thunar";
          version = "4.20.4";

          src = pkgs.fetchurl {
            url = "https://archive.xfce.org/src/xfce/thunar/4.20/thunar-${version}.tar.bz2";
            sha256 = "sha256-xPL8VdKF3u8TSFmEfvbw6Qlu15h+96oGbeWp40ehX9k=";
          };

          nativeBuildInputs = with pkgs; [
            # Build system requirements
            pkg-config
            wrapGAppsHook
            
            # Documentation (matching original)
            docbook_xsl
            libxslt
          ];

          buildInputs = with pkgs; [
            # Core dependencies (matching original exactly)
            xfce.exo
            gdk-pixbuf
            gtk3
            xorg.libX11
            libexif # image properties page
            libgudev
            libnotify
            xfce.libxfce4ui
            xfce.libxfce4util
            pcre2 # search & replace renamer
            xfce.xfce4-panel # trash panel applet plugin
            xfce.xfconf
          ];

          # Add your patch file here
          patches = [
            ./pipe.patch
            # Add more patches as needed
          ];

          # Use the same configure flags as the original
          configureFlags = [ "--with-custom-thunarx-dirs-enabled" ];

          # No need for postUnpack or preConfigure with tarball source

          # Apply the same security patch as the original
          postPatch = ''
            sed -i -e 's|thunar_dialogs_show_insecure_program (parent, _(".*"), file, exec)|1|' thunar/thunar-file.c
          '';

          # Same preFixup as original to ensure exo is in PATH
          preFixup = ''
            gappsWrapperArgs+=(
              # https://github.com/NixOS/nixpkgs/issues/329688
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.xfce.exo ]}
            )
          '';

          enableParallelBuilding = true;

          meta = with pkgs.lib; {
            description = "Xfce file manager";
            longDescription = ''
              Thunar is a modern file manager for the Xfce Desktop Environment.
              It has been designed from the ground up to be fast and easy to use.
            '';
            homepage = "https://docs.xfce.org/xfce/thunar/start";
            license = licenses.gpl2Plus;
            maintainers = with maintainers; [ ];
            platforms = platforms.linux;
            mainProgram = "thunar";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Development dependencies
            autoreconfHook
            pkg-config
            intltool
            gettext
            docbook_xsl
            libxslt
            xfce.xfce4-dev-tools
            
            # Runtime dependencies for development
            xfce.exo
            gdk-pixbuf
            gtk3
            xorg.libX11
            libexif
            libgudev
            libnotify
            xfce.libxfce4ui
            xfce.libxfce4util
            pcre2
            xfce.xfce4-panel
            xfce.xfconf
            
            # Debugging tools
            gdb
            valgrind
          ];
        };
      });
}
