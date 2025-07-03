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
            
            # Wayland core libraries
            wayland
            wayland-protocols
            wayland-scanner
            
            # Graphics and rendering
            cairo
            pango
            
            # Hyprland and related
            hyprland
            hyprland-protocols
            
            # JSON parsing (for Hyprland IPC)
            nlohmann_json
            
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
            echo "Wayland/Hyprland libraries available:"
            echo "  - wayland-client: $(pkg-config --modversion wayland-client 2>/dev/null || echo 'not found')"
            echo "  - cairo: $(pkg-config --modversion cairo 2>/dev/null || echo 'not found')"
            echo "  - nlohmann_json available"
            echo ""
            echo "Next steps:"
            echo "  1. Test Wayland client connection"
            echo "  2. Set up Hyprland IPC communication"
            echo "  3. Create basic workspace enumeration"
            echo ""
          '';
        };
      });
}
