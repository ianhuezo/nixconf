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
            timeout = 2400;
            on-timeout = "hyprlock";
          }
          {
            timeout = 3600;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
  };
}
