{
  inputs,
  config,
  pkgs,
  gtkThemeFromScheme,
  ...
}:
let
  nix-colors = import inputs.nix-colors { };
  neovim = import ./modules/programs/neovim { inherit inputs; };
  quickshellPath = /etc/nixos/dotfiles/quickshell;
  agsPath = /etc/nixos/dotfiles/ags;
  cavaPath = /etc/nixos/dotfiles/cava;
  scriptsPath = /etc/nixos/dotfiles/scripts;
  vesktopThemePath = /etc/nixos/dotfiles/vesktop/themes;
  nix-colors-lib = nix-colors.lib.contrib { inherit pkgs; };
  leftMonitor = "HDMI-A-1";
  rightMonitor = "DP-1";
  startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
    xrandr --output DP-1 --primary & disown
    hyprlock & disown
    sleep 1
    swww-daemon &
    sleep 1
    swww img ${config.home.homeDirectory}/Pictures/frieren.png --transition-type any & disown
    sleep 1
    # Other startup commands
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    nm-applet --indicator & disown
    systemctl --user import-environment XDG_CURRENT_DESKTOP XDG_SESSION_TYPE & disown
    quickshell & disown
  '';
in
{

  imports = [
    nix-colors.homeManagerModules.default
    ./modules/programs/neovim
    ./modules/programs/kitty
    ./modules/programs/mako
    ./modules/shells/zsh
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "ianh";
  home.homeDirectory = "/home/ianh";

  colorScheme = import ../themes/dark-ethereal;

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
    inputs.quickshell.packages.${pkgs.system}.default
    inputs.hyprland-qtutils.packages.${pkgs.system}.default
    qt6.full
    qt6.qtdeclarative
  ];
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

  programs.hyprlock = {
    enable = true;
    extraConfig = ''
            # BACKGROUND
            background {
                monitor =
                path = ${config.home.homeDirectory}/Pictures/frieren.png
                blur_size = 0
                blur_passes = 1
                noise = 0.0117
                contrast = 1.300
                brightness = 0.600
                vibrancy = 0.2100
                vibrancy_darkness = 0.0
            }

            # GENERAL
            general {
                no_fade_in = false
                grace = 0
                disable_loading_bar = true
            }

            # INPUT FIELD
            input-field {
                monitor =
                size = 250, 50
                outline_thickness = 3
                dots_size = 0.26 # Scale of input-field height, 0.2 - 0.8
                dots_spacing = 0.64 # Scale of dots' absolute size, 0.0 - 1.0
                dots_center = true
                outer_color = rgba(0, 0, 0, 0)
                inner_color = rgba(0, 0, 0, 0.5)
                font_color = rgb(200, 200, 200)
                fade_on_empty = true
                placeholder_text = <i><span foreground="##cdd6f4">Password...</span></i>
                hide_input = false
                position = 0, 80
                halign = center
                valign = bottom
            }

            # TIME
            label {
                monitor =
                text = cmd[update:1000] echo "<b><big> $(date +"%-H:%M:%S") </big></b>"
                color = rgba(255, 255, 255, 0.6)
                font_size = 100
                font_family = JetBrains Mono Nerd Font
                position = 0, 16
                halign = center
                valign = center
            }
            # DATE
            label {
              monitor =
              text = cmd[update:18000000] echo "<b> $(date + "%A, %-d %B %Y") </b>"
              color = rgba(255,255,255,0.6)
              font_size = 36
              font_family = JetBrains Mono Nerd Font

              position = 0, -46
              halign = center
              valign = center
            }

            # USER
            label {
                monitor =
                text = Greetings, Ian 
                color = rgba(255, 255, 255, 0.8)
                font_size = 24
                font_family = JetBrains Mono Nerd Font Mono
                position = 0, 30
      	        shadow_passes = 1
      	        shadow_boost = 1.2
      	        shadow_size = 3
      	        shadow_color = rgb(#${config.colorScheme.palette.base00})
                halign = center
                valign = bottom
            }
    '';
  };

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

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = {
      exec-once = [
        ''${startupScript}/bin/start''
      ];
      monitor = [
        "${rightMonitor}, 1920x1080@119.98, auto-right, 1"
        "${leftMonitor}, preferred, auto-left, 1"
      ];
      windowrulev2 = [
        "idleinhibit fullscreen, class:^(vlc)$"
        "float,class:^(thunar|Thunar)$"
        "center,class:^(thunar|Thunar)$"

        # Path of Exile 2 - fullscreen game
        "tag +poe, class:(steam_app_2694490)"
        "tile, class:(steam_app_2694490)"
        "fullscreen, class:(steam_app_2694490)"

        # Exiled Exchange 2 - overlay tool
        "tag +apt, title:(exiled-exchange-2|Exiled Exchange 2)"
        "float, tag:apt"
        "noblur, tag:apt"
        "nofocus, tag:apt"
        "noshadow, tag:apt"
        "noborder, tag:apt"
        "pin, tag:apt"
        "renderunfocused, tag:apt"
        "size 100% 100%, tag:apt"
        "move 0 0, tag:apt"
        "stayfocused, class:(steam_app_2694490)"
      ];
      layerrule = [
        "blur, notifications"
        "ignorezero, notifications"
      ];
      workspace = [
        "1,monitor:${rightMonitor},default:true"
        "2,monitor:${rightMonitor}"
        "3,monitor:${rightMonitor}"
        "4,monitor:${rightMonitor}"
        "5,monitor:${rightMonitor}"

        "6,monitor:${leftMonitor},default:true"
        "7,monitor:${leftMonitor}"
        "8,monitor:${leftMonitor}"
        "9,monitor:${leftMonitor}"
        "10,monitor:${leftMonitor}"
      ];
      "$mod" = "SUPER";
      "$menu" = "qs ipc call dashboard toggleDashboard";
      binds.allow_workspace_cycles = true;
      # binds.allow_pin_fullscreen = false;
      bindm = [
        "$mod, mouse:272, movewindow"
      ];
      bind = [
        "$mod, SPACE, exec, $menu"
        #mod key opens general applications
        "$mod, F, exec, firefox"
        "$mod, K, exec, kitty"
        "$mod, S, exec, spotify --enable-features=UseOzonePlatform --ozone-platform=x11 --uri=%U"
        "$mod, D, exec, vesktop --enable-features=UseOzonePlatform --ozone-platform=x11 --uri=%U"
        "$mod SHIFT, L, exec, hyprlock"
        "$mod SHIFT, S, exec, hyprshot -m region --clipboard-only"
        # "CTRL, TAB, overview:toggle"
        "$mod, Q, killactive"
        "$mod, B, exec, qs ipc call bar toggleBar"
        "$mod SHIFT, Q, exec,loginctl terminate-user $USER"
        "$mod SHIFT, F, fullscreen"
        "$mod, N, exec, hyprctl dispatch togglefloating"
        #mod with left mouse moves windows
        ", Print, exec, grimblast copy area"
        #Kitty specific open another kitty terminal instead of splitting the kitty terminal
        "CTRL_SHIFT, Return, exec, kitty --directory=$HOME"
        "CTRL_SHIFT, bracketleft, cyclenext, prev"
        "CTRL_SHIFT, bracketright, cyclenext"
        "SHIFT,Space,pass,title:^(exiled-exchange-2)$"
        "CTRL,D,pass,class:^(exiled-exchange-2)$"
        "CTRL ALT,D,pass,class:^(exiled-exchange-2)$"
      ]
      ++ (
        # binds $mod + [shift +] {Q,W,E,R,T,Y,U,I,O} to [move to] workspace {1..9}
        builtins.concatLists (
          builtins.genList (
            i:
            let
              ws = i + 1;
            in
            [
              "$mod, code:1${toString i}, workspace, ${toString ws}"
            ]
          ) 9
        )
      );
      #tokyodark theme applied
      general = {
        resize_on_border = true;
        hover_icon_on_border = true;
        gaps_in = 3;
        gaps_out = 3;
        border_size = 1;
        "col.active_border" =
          "rgba(${config.colorScheme.palette.base0C}ee) rgba(${config.colorScheme.palette.base01}ee) 45deg";
        "col.inactive_border" = "rgba(${config.colorScheme.palette.base03}aa)";
        layout = "master";
      };
      decoration = {
        rounding = 10;
      };
      cursor = {
        no_hardware_cursors = true;
      };
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };
      animations = {
        enabled = "yes";
        # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

        bezier = [
          "specialcubic, 0.34, 1.56, 0.64, 1"
          "specialCubicReverse2, 0, -0.07, 1, -0.35"
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 1.1, 0.1, 1.1"
          "winOut, 0.3, -0.3, 0, 1"
          "linear, 1, 1, 1, 1"
          "Cubic, 0.1, 0.1, 0.1, 1"
          "overshot, 0.05, 0.9, 0.1, 1.1"
          "ease-in-out, 0.17, 0.67, 0.83, 0.67"
          "ease-in, 0.17, 0.67, 0.83, 0.67"
          "ease-out, 0.42, 0, 1, 1"
          "easeInOutSine, 0.37, 0, 0.63, 1"
          "easeInSine, 0.12, 0, 0.39, 0"
          "easeOutSine, 0.61, 1, 0.88, 1"
        ];
        animation = [
          "windowsIn, 1, 4, easeInOutSine, slide"
          "windowsOut, 1, 4, easeInOutSine, slide"
          "border, 1, 3, easeInOutSine"
          "borderangle, 1, 30, easeInOutSine, loop"
          "workspacesIn, 1, 3, easeInOutSine, slidefade"
          "workspacesOut, 1, 3, easeInOutSine, slidefade"
          "specialWorkspaceIn, 1, 3, easeInOutSine, slidevert"
          "specialWorkspaceOut, 1, 3, easeInOutSine, slidevert"
          "layersIn, 1, 3, easeInOutSine, fade"
          "layersOut, 1, 3, easeInOutSine, fade"
        ];
      };
    };
  };
  wayland.windowManager.hyprland.systemd.variables = [ "--all" ];
  #hyprland plugins
  wayland.windowManager.hyprland.plugins = [
    # inputs.Hyprspace.packages.${pkgs.system}.Hyprspace
  ];
  qt.platformTheme = "gtk";
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
  };
  #
  gtk = {
    enable = true;
    font = {
      name = "JetBrains Mono Nerd Font";
      size = 12;
    };
    theme = {
      package = gtkThemeFromScheme { scheme = config.colorScheme; };
      name = "${config.colorScheme.slug}";
    };
    iconTheme = {
      name = "Tela-dark";
      package = pkgs.tela-icon-theme;
    };

  };

  home.file.".config/quickshell".source = config.lib.file.mkOutOfStoreSymlink quickshellPath;
  home.file.".config/ags".source = config.lib.file.mkOutOfStoreSymlink agsPath;
  home.file.".config/custom_scripts".source = config.lib.file.mkOutOfStoreSymlink scriptsPath;
  home.file.".config/cava_conf".source = config.lib.file.mkOutOfStoreSymlink cavaPath;
  home.file.".config/vesktop/themes".source = config.lib.file.mkOutOfStoreSymlink vesktopThemePath;
  home.file."${config.home.homeDirectory}/Pictures" = {
    source = ../../wallpapers;
    recursive = true;
  };

  home.sessionVariables = {
    XDG_CACHE_HOME = "${config.home.homeDirectory}/var/.cache";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    XDG_CONFIG_DIRS = "${config.home.homeDirectory}/etc/xdg";
    XDG_DATA_HOME = "${config.home.homeDirectory}/var/share";
    XDG_STATE_HOME = "${config.home.homeDirectory}/var/state";
    XDG_DATA_DIRS = "/usr/local/share/:/usr/share/:/etc/profiles/per-user/$USER/share/:/run/current-system/sw/share/:${config.home.homeDirectory}/.local/share/";
    XDG_PICTURES_DIR = "${config.home.homeDirectory}/pictures";
    NIXOS_XDG_OPEN_USE_PORTAL = "1";
    QT_QPA_PLATFORM = "wayland";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    NIXOS_OZONE_WL = "1";
    STEAMVR_LH_ENABLE = "true";
    QS_CONFIG_PATH = "${config.home.homeDirectory}/.config/quickshell";
    QS_BASE_PATH = "${config.home.homeDirectory}/.config/quickshell";
    QML2_IMPORT_PATH = "${pkgs.qt6.qtdeclarative}/${pkgs.qt6.qtbase.qtQmlPrefix}:${
      inputs.quickshell.packages.${pkgs.system}.default
    }/lib/qt-6/qml:${config.home.homeDirectory}/.config/quickshell";
    QML_IMPORT_PATH = "${config.home.homeDirectory}/.config/quickshell";
    QT_QML_ROOT_PATH = "${config.home.homeDirectory}/.config/quickshell";
  };

  programs.home-manager.enable = true;
}
