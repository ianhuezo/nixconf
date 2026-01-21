{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.rust;
in
{
  options.modules.rust = {
    enable = mkEnableOption "Rust development environment";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
    ];

    home.sessionVariables = {
      RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
    };
  };
}
