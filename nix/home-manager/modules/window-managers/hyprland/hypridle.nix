{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.hypridle;
in
{
  options.modules.hypridle = {
    enable = mkEnableOption "Enable hypridle config for hyprland";
  };
  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;

      settings = {
        general = {
          ignore_dbus_inhibit = false;
          after_sleep_cmd = "hyprctl dispatch dpms on";
          lock_cmd = "hyprlock";
        };
        listener = [
          {
            timeout = 900; # 15 minutes
            on-timeout = "hyprlock";
          }
          {
            timeout = 1200; # 20 minutes
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
  };
}
