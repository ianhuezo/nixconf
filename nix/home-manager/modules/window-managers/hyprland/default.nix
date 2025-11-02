{
  lib,
  pkgs,
  config,
  inputs,
  gtkThemeFromScheme,
  ...
}:
with lib;
let
  cfg = config.modules.hyprland;
  leftMonitor = "HDMI-A-1";
  rightMonitor = "DP-2";
  quickshellPath = "/etc/nixos/dotfiles/quickshell/shell.qml";
  startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
    xrandr --output DP-2 --primary & disown
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
    sleep 1
    QS_ICON_THEME="Tela-dark" quickshell -p ${quickshellPath} & disown
  '';

in
{
  imports = [
    ./hypridle.nix
    ./hyprlock.nix
    ../../quickshell
  ];
  options.modules.hyprland = {
    enable = mkEnableOption "Enable hyprland as the window compositor";
    colorScheme = mkOption {
      default = null;
      description = "base16 colorscheme for hyprland";
      type = types.attrs;
    };
  };
  config = mkIf cfg.enable {
    home.packages = [
      inputs.hyprland-qtutils.packages.${pkgs.system}.default
      inputs.swww.packages.${pkgs.system}.swww
      inputs.hexecute.packages.${pkgs.system}.default
      pkgs.slurp
      pkgs.grim
    ];
    modules.hypridle = {
      enable = true;
    };
    modules.hyprlock = {
      enable = true;
      inherit (cfg) colorScheme;
    };
    modules.quickshell = {
      enable = true;
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
        #bound to extra mouse button
        "$mod1" = "Super_L";
        "$menu" = "qs ipc -p ${quickshellPath} call dashboard toggleDashboard";
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
          "$mod, B, exec, qs ipc -p ${quickshellPath} call bar toggleBar"
          "$mod SHIFT, Q, exec,loginctl terminate-user $USER"
          "$mod SHIFT, F, fullscreen"
          "$mod, N, exec, hyprctl dispatch togglefloating"
          ", mouse:276, exec, hexecute"
          #mod with left mouse moves windows
          ", Print, exec, grim -g \"$(slurp -d)\" - | tee ~/Pictures/screenshot.png | wl-copy" # Kitty specific open another kitty terminal instead of splitting the kitty terminal
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
    home.sessionVariables = {
      QS_ICON_THEME = "Tela-dark";
    };
  };
}
