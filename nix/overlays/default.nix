[
  (import ./hyprland)
  (import ./thunar)
  (import ./vesktop)
  (import ./claude-code)
  (import ./yt-dlp)
  # WIP, does not build: the 0.18.2 -> 0.33.2 overrideAttrs fails in ollama's
  # restructured Makefile build. Re-enable once that is resolved -- see the
  # notes in ./ollama/default.nix.
  # (import ./ollama)
  # (import ./other-package.nix)
  # Add more overlays as needed
]
