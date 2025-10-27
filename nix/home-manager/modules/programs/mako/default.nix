{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.mako;
in
{
  options.modules.mako = {
    # Changed from 'kitty' to 'mako'
    enable = mkEnableOption "Mako notification system";
    colorScheme = mkOption {
      type = types.attrs;
      description = "Color scheme configuration with palette";
    };
  };
  config = mkIf cfg.enable {
    services.mako = {
      enable = true;
      extraConfig = ''
        default-timeout=10000
        font=JetBrains Mono Nerd Font
        background-color=#${config.colorScheme.palette.base00}80
        border-radius=20
        padding=10,5,10,5
        border-color=#${config.colorScheme.palette.base0C}
        border-size=2
      '';
    };
  };
}
