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
		
};
	
	outputs = { nixpkgs, home-manager, nixvim,... }:
		let
			lib = nixpkgs.lib;
			system = "x86_64-linux";
			pkgs = import nixpkgs { inherit system; };
		in {
			homeConfigurations = {
				ianh = home-manager.lib.homeManagerConfiguration {
					inherit pkgs;
					modules = [ 
						./hardware-configuration.nix
						./configuration.nix
						./home.nix 
						nixvim.homeManagerModules.nixvim
					];
				};
							};
		};
}
