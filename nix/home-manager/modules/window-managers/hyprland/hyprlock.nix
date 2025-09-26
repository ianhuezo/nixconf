{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.hyprlock;
in
{
  options.modules.hyprlock = {
    enable = mkEnableOption "Enable hyprlock config for hyprland";
    # colorScheme = mk
  };
  config = mkIf cfg.enable {

  };
}
