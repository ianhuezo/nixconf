# shell.nix
let
  # We pin to a specific nixpkgs commit for reproducibility.
  # Last updated: 2024-04-29. Check for new commits at https://status.nixos.org.
  pkgs =
    import
      (fetchTarball "https://github.com/NixOS/nixpkgs/archive/3a228057f5b619feb3186e986dbe76278d707b6e.tar.gz")
      { };
in
pkgs.mkShell {
  packages = [
    pkgs.ffmpeg
    (pkgs.python3.withPackages (
      python-pkgs: with python-pkgs; [
        # select Python packages here
        yt-dlp
      ]
    ))
  ];
}
