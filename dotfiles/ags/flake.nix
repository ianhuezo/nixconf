{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ags, astal }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [
        (ags.packages.${system}.default.override { 
          extraPackages = [
            # cherry pick packages
          ]});
      ];
      packages = with pkgs; [
        # AGS dependencies
        ags.packages.${system}.default
        nodejs
        nodePackages.typescript
        wrapGAppsHook
        gobject-introspection
        gtk3
        gtk-layer-shell

        # Astal packages
        astal.packages.${system}.astal3
        astal.packages.${system}.io
        astal.packages.${system}.hyprland
        astal.packages.${system}.mpris
        astal.packages.${system}.network
        astal.packages.${system}.bluetooth
        astal.packages.${system}.battery
      ];

      shellHook = ''
        echo "AGS + Astal development environment loaded"
      '';
    };
  };
}
