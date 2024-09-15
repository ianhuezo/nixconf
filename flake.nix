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
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    hyprland-direct = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    };
    #    hyprland-plugins = {
    # url = "github:hyprwm/hyprland-plugins";
    # inputs.hyprland-direct.follows = "hyprland";
    #    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nixvim,
      plasma-manager,
      hyprland-direct,
      ...
    }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations = {
        joyboy = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit hyprland-direct;
          };
          modules = [
            ./configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ianh.imports = [
                # plasma-manager.homeManagerModules.plasma-manager
                nixvim.homeManagerModules.nixvim
                ./home.nix
              ];
            }
          ];
        };
      };
    };
}
