{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.xdg;
in
{
  options.modules.xdg = {
    enable = mkEnableOption "Enable xdg for Linux";
  };

  config = mkIf cfg.enable {
    xdg.enable = true;
    xdg.cacheHome = "${config.home.homeDirectory}/var/.cache";
    xdg.dataHome = "${config.home.homeDirectory}/var/share";
    xdg.stateHome = "${config.home.homeDirectory}/var/state";
    xdg.portal = {
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ];
    };
    #VR config files written in home manager
    xdg.configFile."openxr/1/active_runtime.json".source =
      "${pkgs.monado}/share/openxr/1/openxr_monado.json";
    xdg.configFile."openvr/openvrpaths.vrpath".text = ''
      {
        "config" :
        [
          "${config.xdg.dataHome}/Steam/config"
        ],
        "external_drivers" : null,
        "jsonid" : "vrpathreg",
        "log" :
        [
          "${config.xdg.dataHome}/Steam/logs"
        ],
        "runtime" :
        [
          "${pkgs.opencomposite}/lib/opencomposite"
        ],
        "version" : 1
      }
    '';
    home.sessionVariables = {
      XDG_CACHE_HOME = "${config.home.homeDirectory}/var/.cache";
      XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
      XDG_CONFIG_DIRS = "${config.home.homeDirectory}/etc/xdg";
      XDG_DATA_HOME = "${config.home.homeDirectory}/var/share";
      XDG_STATE_HOME = "${config.home.homeDirectory}/var/state";
      XDG_DATA_DIRS = "/usr/local/share/:/usr/share/:/etc/profiles/per-user/$USER/share/:/run/current-system/sw/share/:${config.home.homeDirectory}/.local/share/:${pkgs.tela-icon-theme}/share";
      XDG_PICTURES_DIR = "${config.home.homeDirectory}/pictures";
      NIXOS_XDG_OPEN_USE_PORTAL = "1";
    };
  };
}
