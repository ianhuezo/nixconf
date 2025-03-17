{
  inputs,
  config,
  pkgs,
  gtkThemeFromScheme,
  ...
}:
let
  nix-colors = import inputs.nix-colors { };
  neovim = import ./nix/programs/neovim { inherit inputs; };
  quickshellPath = /etc/nixos/dotfiles/quickshell;
  agsPath = /etc/nixos/dotfiles/ags;
  cavaPath = /etc/nixos/dotfiles/cava;
  scriptsPath = /etc/nixos/dotfiles/scripts;
  leftMonitor = "HDMI-A-1";
  rightMonitor = "DP-1";
  startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
    xrandr --output DP-1 --primary & disown
    sleep 1
    hyprlock & disown
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    nm-applet --indicator & disown 
    swww-daemon & disown
    sleep 1
    swww img ${config.home.homeDirectory}/Pictures/frieren.png --transition-type any & disown
    sleep 1
    systemctl --user import-environment XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
    sleep 1
  '';
in
{

  imports = [
    nix-colors.homeManagerModules.default
    ./nix/programs/neovim
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "ianh";
  home.homeDirectory = "/home/ianh";
  #import the preferred color scheme
  colorScheme = nix-colors.colorSchemes.tokyo-city-dark;

  modules.neovim = {
    enable = true;
    colorScheme = config.colorScheme;
  };

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
    krabby
    fastfetch
    vlc
    fastfetch
    qbittorrent
    zoxide
    zsh
    discord
    webcord
    kitty
    vesktop
    bash
    spotify
    gh
    typescript
    typescript-language-server
    starship
    inputs.quickshell.packages.${pkgs.system}.default
    inputs.hyprland-qtutils.packages.${pkgs.system}.default
    qt6.full
    qt6.qtdeclarative
  ];
  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;
  programs.starship = {
    enable = true;
  };
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
  programs.wofi.enable = true;
  programs.wofi.settings = {
    width = 300;
    height = 350;
    always_parse_args = true;
    hide_scroll = true;
    show_all = false;
    insensitive = true;
  };
  programs.wofi.style = ''
        #window {
           border-radius: 15px;
           background-color: #${config.colorScheme.palette.base00};
           padding: 5px;
        }
        #outer-box {
    	border: 1px solid #${config.colorScheme.palette.base0E};
    	border-radius:15px;
        }
        #img {
    	margin-left: 16px;
        }
        #input{
        	margin: 15px;
    	box-shadow: none;
    	border: none;
    	opacity: 0.9;
    	background-color: #${config.colorScheme.palette.base00};
        }
        #input:focus{
    	border-image: none;
        }
        #text {
    	margin-left: 10px;
        }
        #entry:selected {
          all: unset;
          background-color: #${config.colorScheme.palette.base0D};
          border-radius: 5px;
          font-size: 0.8em;
        }
        #entry:selected:last-child {
    	border-bottom-right-radius: 15px;
    	border-bottom-left-radius: 15px;
        }
        #entry {
          border-radius: 5px;
          font-size: 0.8em;
        }
        #scroll {
            all: unset;
    	border: none;
        }
        #entry:focus {
            background: #${config.colorScheme.palette.base0D};
    	font-size: 0.8em;
        }
        *{
          font-family: monospace;
          font-size: 1.04em;
          font-weight: bold;
          color: #${config.colorScheme.palette.base07};
        }
  '';
  services.mako = {
    enable = true;
    defaultTimeout = 10000;
    font = "JetBrains Mono Nerd Font Mono";
    backgroundColor = "#${config.colorScheme.palette.base00}80";
    borderRadius = 20;
    padding = "10,5,10,5";
    borderColor = "#${config.colorScheme.palette.base0C}";
    borderSize = 2;
  };
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
      "$menu" = "wofi -a --allow-images --show drun";
      binds.allow_workspace_cycles = true;
      # binds.allow_pin_fullscreen = false;
      bindm = [
        "$mod, mouse:272, movewindow"
      ];
      bind =
        [
          #search with wofi
          "ALT_L, SPACE, exec, $menu"
          #mod key opens general applications
          "$mod, F, exec, firefox"
          "$mod, K, exec, kitty"
          "$mod, S, exec, spotify --enable-features=UseOzonePlatform --ozone-platform=x11 --uri=%U"
          "$mod, D, exec, vesktop --enable-features=UseOzonePlatform --ozone-platform=x11 --uri=%U"
          "$mod SHIFT, L, exec, hyprlock"
          #mod shift does things to workspaces, monitors, etc
          "$mod SHIFT, N, cyclenext"
          "$mod SHIFT, P, cyclenext, prev"
          "$mod SHIFT, S, exec, hyprshot -m region --clipboard-only"
          # "CTRL, TAB, overview:toggle"
          "$mod, Q, killactive"
          "$mod, B, exec, ~/.config/custom_scripts/quickshell_toggle.sh"
          "$mod SHIFT, Q, exec,loginctl terminate-user $USER"
          "$mod SHIFT, F, fullscreen"
          "$mod, N, exec, hyprctl dispatch togglefloating"
          #mod with left mouse moves windows
          ", Print, exec, grimblast copy area"
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
      animations = {
        enabled = "yes";

        # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
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

    theme = {
      package = gtkThemeFromScheme { scheme = config.colorScheme; };
      name = "${config.colorScheme.slug}";
    };
    iconTheme = {
      name = "Tela-dark";
      package = pkgs.tela-icon-theme;
    };
    #
    #   font = {
    #     name = "Sans";
    #     size = 11;
    #   };
  };
  programs.kitty = {
    enable = true;
    extraConfig = ''
      		       font_family Maple Mono
      		       bold_font Maple Mono
      		       bold_italic_font Maple Mono
            	               background_opacity 0.85
                             foreground #${config.colorScheme.palette.base05} 
                             background #${config.colorScheme.palette.base00} 
                             
                             # grayish
                             color0 #${config.colorScheme.palette.base03} 
                             color8 #${config.colorScheme.palette.base03} 
                             
                             # Salmon
                             color1 #${config.colorScheme.palette.base08} 
                             color9 #${config.colorScheme.palette.base08} 
                             
                             # Green
                             color2  #${config.colorScheme.palette.base0C} 
                             color10 #${config.colorScheme.palette.base0C} 
                             
                             # Yellow-brown
                             color3  #${config.colorScheme.palette.base09} 
                             color11 #${config.colorScheme.palette.base09} 
                             
                             # Blue
                             color4  #${config.colorScheme.palette.base0D} 
                             color12 #${config.colorScheme.palette.base0D}
                             
                             # Magenta
                             color5  #${config.colorScheme.palette.base0E} 
                             color13 #${config.colorScheme.palette.base0E}
                             
                             # Cyan
                             color6  #${config.colorScheme.palette.base0C} 
                             color14 #${config.colorScheme.palette.base0C} 
                             
                             # White
                             color7  #${config.colorScheme.palette.base05} 
                             color15 #${config.colorScheme.palette.base05} 
                             
                             # Cursor
                             cursor #${config.colorScheme.palette.base05} 
                             cursor_text_color #${config.colorScheme.palette.base00} 
                             
                             # Selection highlight
                             selection_foreground none
                             selection_background #${config.colorScheme.palette.base03}
                             
                             # The color for highlighting URLs on mouse-over
                             url_color #${config.colorScheme.palette.base0B}
                             
                             # Window borders
                             active_border_color #${config.colorScheme.palette.base0D}
                             inactive_border_color #${config.colorScheme.palette.base00}
                             bell_border_color #${config.colorScheme.palette.base09}
                             
                             # Tab bar
                             tab_bar_style fade
                             tab_fade 1
                             active_tab_foreground   #3d59a1
                             active_tab_background   #16161e
                             active_tab_font_style   bold
                             inactive_tab_foreground #787c99
                             inactive_tab_background #16161e
                             inactive_tab_font_style bold
                             tab_bar_background #101014
    '';
  };
  home.file.".config/quickshell".source = config.lib.file.mkOutOfStoreSymlink quickshellPath;
  home.file.".config/ags".source = config.lib.file.mkOutOfStoreSymlink agsPath;
  home.file.".config/custom_scripts".source = config.lib.file.mkOutOfStoreSymlink scriptsPath;
  home.file.".config/cava_conf".source = config.lib.file.mkOutOfStoreSymlink cavaPath;
  home.file."${config.home.homeDirectory}/Pictures" = {
    source = ./wallpapers;
    recursive = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --flake .#joyboy";
      nixfmt = "sudo nixfmt";
      cd = "z";
    };
    history = {
      size = 10000;
      path = "$XDG_DATA_HOME/zsh/history";
    };
    initExtra = ''
          	bindkey '^ ' autosuggest-execute
      	fastfetch
      	krabby random 1-3 --no-title
    '';
    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.4.0";
          sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
        };
      }
    ];
  };

  nixpkgs.config.home.allowUnfree = true;
  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/ianh/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    XDG_CACHE_HOME = "${config.home.homeDirectory}/var/.cache";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    XDG_CONFIG_DIRS = "${config.home.homeDirectory}/etc/xdg";
    XDG_DATA_HOME = "${config.home.homeDirectory}/var/share";
    XDG_STATE_HOME = "${config.home.homeDirectory}/var/state";
    XDG_DATA_DIRS = "/usr/local/share/:/usr/share/:/etc/profiles/per-user/$USER/share/:/run/current-system/sw/share/";
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
    }/lib/qt-6/qml";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
