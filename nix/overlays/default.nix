# overlays/default.nix
[
  # Import individual overlay files
  (import ./hyprland)
  (import ./thunar)
  (import ./vesktop)
  # (import ./yt-dlp)  # Temporarily disabled - build failing
  (import ./claude-code) # Temporarily disabled - using nixpkgs version
  # (import ./tela-icon-theme)
  # (import ./other-package.nix)
  # Add more overlays as needed
]
