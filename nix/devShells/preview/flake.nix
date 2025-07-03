{
  description = "Hyprland Workspace Preview - C++ Development Environment";

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
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # C++ compiler and build tools
            gcc
            cmake
            pkg-config
            
            # Development tools
            gdb
            valgrind
            
            # Basic Wayland/Hyprland dependencies (we'll expand this later)
            wayland
            wayland-protocols
            
            # Useful utilities
            tree
            which
          ];

          shellHook = ''
            echo "🚀 Hyprland Workspace Preview Development Environment"
            echo "Available tools:"
            echo "  - gcc $(gcc --version | head -n1)"
            echo "  - cmake $(cmake --version | head -n1)"
            echo "  - pkg-config $(pkg-config --version)"
            echo ""
            echo "Next steps:"
            echo "  1. Create a simple C++ hello world"
            echo "  2. Set up CMake build system"
            echo "  3. Test compilation"
            echo ""
          '';
        };
      });
}
