{
  description = "My Home Manager Configuration";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      #?rev=12f9a0d0b93f691d4d9923716557154d74777b0a
      url = "git+https://github.com/hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    Hyprspace = {
      url = "github:KZDKM/Hyprspace";
      # Hyprspace uses latest Hyprland. We declare this to keep them in sync.
      inputs.hyprland.follows = "hyprland";
    };
    nix-colors.url = "github:misterio77/nix-colors";
    swww.url = "github:LGFae/swww/412326e40a399e61e15a31147569e97c69900dba";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell?ref=0499518143b232b949a177c5fea929f2ceed58ec";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-qtutils = {
      url = "github:hyprwm/hyprland-qtutils";
    };
    # stylix = {
    #   url = "github:danth/stylix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # nixpkgs-xr = {
    #   url = "github:nix-community/nixpkgs-xr";
    # };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations = {
        "joyboy" = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            # inputs.nixpkgs-xr.nixosModules.nixpkgs-xr
            ./nix/joyboy/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-backup";
              home-manager.extraSpecialArgs = {
                inherit inputs;
                inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
              };
              home-manager.users.ianh.imports = [
                ./home.nix
              ];
            }
          ];
        };
      };
    };
}
