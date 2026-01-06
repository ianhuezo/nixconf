{
  inputs,
  config,
  pkgs,
  ...
}:
let
  nix-colors = import inputs.nix-colors { };
  agsPath = /etc/nixos/dotfiles/ags;
  cavaPath = /etc/nixos/dotfiles/cava;
  scriptsPath = /etc/nixos/dotfiles/scripts;
  vesktopThemePath = /etc/nixos/dotfiles/vesktop/themes;
  assetsPath = /etc/nixos/dotfiles/assets;
  fullScheme = import ../themes/dark-ethereal;
in
{

  imports = [
    nix-colors.homeManagerModules.default
    ./modules/programs/neovim
    ./modules/programs/kitty
    ./modules/programs/mako
    ./modules/shells/zsh
    ./modules/xdg
    ./modules/quickshell
    ./modules/window-managers/hyprland
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "ianh";
  home.homeDirectory = "/home/ianh";
  #TODO for later I'll need to add this theme to places
  colorScheme = removeAttrs fullScheme [ "theme" ];
  # theme = fullScheme.theme;

  modules.neovim = {
    enable = true;
    colorScheme = config.colorScheme;
  };

  modules.kitty = {
    enable = true;
    colorScheme = config.colorScheme;
  };

  modules.mako = {
    enable = true;
    colorScheme = config.colorScheme;
  };

  modules.zsh = {
    enable = true;
  };

  modules.xdg = {
    enable = true;
  };

  modules.quickshell = {
    enable = true;
  };
  modules.hyprland = {
    enable = true;
    colorScheme = config.colorScheme;
  };

  programs.vesktop = {
    enable = true;
    settings = {
      splashTheming = true;
      splashColor = "#${config.colorScheme.palette.base05}";
      splashBackground = "#${config.colorScheme.palette.base00}";
      customTitleBar = true;
      tray = false;
      minimizeToTray = false;
    };
  };

  home.file.".syncplay/syncplay.ini".text = ''
    [client_settings]
    mediaplayer = VLC
    vlc_path = ${pkgs.vlc}/bin/vlc
  '';

  # This value determines the Home Manager release that your config.home.ration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    vlc
    qbittorrent
    imagemagick
    bash
    spotify
    gh
    typescript
    typescript-language-server
    syncplay
    claude-code
    inputs.hyprland-qtutils.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home.file.".config/ags".source = config.lib.file.mkOutOfStoreSymlink agsPath;
  home.file.".config/custom_scripts".source = config.lib.file.mkOutOfStoreSymlink scriptsPath;
  home.file.".config/cava_conf".source = config.lib.file.mkOutOfStoreSymlink cavaPath;
  home.file.".config/vesktop/themes".source = config.lib.file.mkOutOfStoreSymlink vesktopThemePath;
  home.file."${config.home.homeDirectory}/Pictures" = {
    source = ../../wallpapers;
    recursive = true;
  };

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    NIXOS_OZONE_WL = "1";
    STEAMVR_LH_ENABLE = "true";
  };

  programs.home-manager.enable = true;
}
