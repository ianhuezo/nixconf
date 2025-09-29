# overlays/default.nix
[
  # Import individual overlay files
  (import ./thunar)
  (import ./yt-dlp)
  # (import ./tela-icon-theme)
  # (import ./other-package.nix)
  # Add more overlays as needed
]
