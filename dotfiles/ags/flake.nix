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

  outputs =
    {
      self,
      nixpkgs,
      ags,
      astal,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.default = ags.lib.bundle {
        inherit pkgs;
        src = ./.;
        name = "test-app"; # name of executable
        entry = "app.tsx";
        gtk4 = true;

        # additional libraries and executables to add to gjs' runtime
        extraPackages = [
          ags.packages.${system}.apps
          ags.packages.${system}.hyprland
          ags.packages.${system}.mpris
          ags.packages.${system}.wireplumber
          ags.packages.${system}.network
          ags.packages.${system}.tray
          ags.packages.${system}.io
          ags.packages.${system}.battery
          ags.packages.${system}.notifd
          ags.packages.${system}.cava
        ];
      };
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          (ags.packages.${system}.default.override {
            extraPackages = [
              ags.packages.${system}.apps
              ags.packages.${system}.hyprland
              ags.packages.${system}.mpris
              ags.packages.${system}.wireplumber
              ags.packages.${system}.network
              ags.packages.${system}.tray
              ags.packages.${system}.io
              ags.packages.${system}.battery
              ags.packages.${system}.notifd
              ags.packages.${system}.cava
            ];
          })
          pkgs.cava
        ];
        shellHook = ''
          echo "AGS + Astal development environment loaded"
        '';
      };
    };
}
