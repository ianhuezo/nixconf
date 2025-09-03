# overlays/default.nix
[
  # Import individual overlay files
  (import ./thunar)
  (import ./yt-dlp)
  # (import ./other-package.nix)
  # Add more overlays as needed
]
