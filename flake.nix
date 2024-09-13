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
                nixos-cosmic = {
                  url = "github:lilyinstarlight/nixos-cosmic";
                  inputs.nixpkgs.follows = "nixpkgs";
                };	
};
	
	outputs = { nixpkgs, home-manager, nixvim, plasma-manager, nixos-cosmic, ... }:
		let
			lib = nixpkgs.lib;
			system = "x86_64-linux";
			pkgs = import nixpkgs { inherit system; };
		in {
			nixosConfigurations = {
				joyboy = lib.nixosSystem {
					inherit system;
					modules = [
						{
						   				   		nix.settings = {
						     					substituters = [ "https://cosmic.cachix.org/" ];
						   				     			trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
						   				   		};
						   				 	}
						    					nixos-cosmic.nixosModules.default
						./configuration.nix
						home-manager.nixosModules.home-manager
						{
							home-manager.useGlobalPkgs = true;
							home-manager.useUserPackages = true;
							home-manager.users.ianh.imports = [
								 plasma-manager.homeManagerModules.plasma-manager 
								nixvim.homeManagerModules.nixvim
								./home.nix
							];
						}
					];
				};
			};
	};
}
