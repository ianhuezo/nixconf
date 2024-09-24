{
  inputs,
  config,
  pkgs,
  ...
}:
let
  nix-colors = import inputs.nix-colors { };
  startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
    nm-applet --indicator & disown 
    systemctl --user import-environment XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    sleep 1
    ags & disown
    sleep 1
    swww-daemon &
    sleep 1
    swww img ${config.home.homeDirectory}/Pictures/frieren.png &
  '';
in
{

  imports = [
    # ./core/plasma/default.nix
    nix-colors.homeManagerModules.default
    inputs.ags.homeManagerModules.default
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "ianh";
  home.homeDirectory = "/home/ianh";

  #import the preferred color scheme
  colorScheme = nix-colors.colorSchemes.tokyo-city-dark;

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
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # config.home.ration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.home.username}!"
    # '')
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
  ];
  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;
  xdg.enable = true;
  xdg.cacheHome = "${config.home.homeDirectory}/var/.cache";
  xdg.dataHome = "${config.home.homeDirectory}/var/share";
  xdg.stateHome = "${config.home.homeDirectory}/var/state";
  xdg.portal = {
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
      xdg-desktop-portal-kde
      xdg-desktop-portal-hyprland
    ];
  };
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
  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 1;
      };
    };
  };
  programs.ags = {
    enable = true;
    extraPackages = with pkgs; [
      gtksourceview
      webkitgtk
      accountsservice
    ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = {
      exec-once = ''${startupScript}/bin/start'';
      monitor = [
        "HDMI-A-1, preferred, auto, 1"
        "DP-2, preferred, auto-left, 1"
      ];
      workspace = [
        "1,monitor:HDMI-A-1,default:true"
        "2,monitor:HDMI-A-1"
        "3,monitor:HDMI-A-1"
        "4,monitor:HDMI-A-1"
        "5,monitor:HDMI-A-1"

        "6,monitor:DP-2,default:true"
        "7,monitor:DP-2"
        "8,monitor:DP-2"
        "9,monitor:DP-2"
        "10,monitor:DP-2"
      ];
      "$mod" = "SUPER";
      "$menu" = "wofi -a --allow-images --show drun";
      binds.allow_workspace_cycles = true;
      bindm = [
        "ALT, mouse:272, movewindow"
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
          #mod shift does things to workspaces, monitors, etc
          "$mod SHIFT, h, movecurrentworkspacetomonitor, l"
          "$mod SHIFT, l, movecurrentworkspacetomonitor, r"
          "$mod SHIFT, N, cyclenext"
          "$mod SHIFT, P, cyclenext, prev"
          "$mod SHIFT, S, exec, hyprshot -m region --clipboard-only"
          "CTRL, TAB, overview:toggle"
          "$mod, Q, killactive"
          "$mod SHIFT, Q, exec,loginctl terminate-user $USER"
          "$mod SHIFT, F, fullscreen"
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
                # " code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            ) 9
          )
        );
      #tokyodark theme applied
      general = {
        resize_on_border = true;
        hover_icon_on_border = true;
        gaps_in = 5;
        gaps_out = 5;
        border_size = 2;
        "col.active_border" = "${config.colorScheme.palette.base08} rgba(${config.colorScheme.palette.base0A}ee) 45deg";
        "col.inactive_border" = "rgba(${config.colorScheme.palette.base03}aa)";
        layout = "master";
      };
      decoration = {
        rounding = 10;
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
    inputs.Hyprspace.packages.${pkgs.system}.Hyprspace
  ];
  # qt.enable = true;
  qt.platformTheme = "gtk";
  gtk = {
    enable = true;
  };

  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
  };
  #
  # gtk = {
  #   enable = true;
  #
  #   theme = {
  #     package = pkgs.flat-remix-gtk;
  #     name = "Flat-Remix-GTK-Grey-Darkest";
  #   };
  #
  #   iconTheme = {
  #     package = pkgs.gnome.adwaita-icon-theme;
  #     name = "Adwaita";
  #   };
  #
  #   font = {
  #     name = "Sans";
  #     size = 11;
  #   };
  # };
  programs.kitty.enable = true;
  home.file."${config.home.homeDirectory}/.config" = {
    source = ./dotfiles;
    recursive = true;
  };
  home.file."${config.home.homeDirectory}/Pictures" = {
    source = ./wallpapers;
    recursive = true;
  };
  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this config.home.ration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the config.home.ration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  programs.nixvim = {
    enable = true;
    globals.mapleader = " ";
    colorschemes.catppuccin.enable = true;
    plugins.lualine.enable = true;
    clipboard.register = "unnamedplus";
    clipboard.providers.wl-copy.enable = true;
  };
  programs.nixvim.plugins = {
    lsp.enable = true;
    typescript-tools = {
      enable = true;
      settings.tsserverPlugins = [ "ags-ts" ];
    };
    lsp.servers.tsserver.enable = true;
    lsp.servers.tsserver.filetypes = [
      "javascript"
      "javascriptreact"
      "javascript.jsx"
      "typescript"
      "typescriptreact"
      "typescript.tsx"
      "vue"
    ];

    treesitter = {
      enable = true;
      settings = {
        auto_install = true;
        highlight = {
          enable = true;
          additional_vim_regex_highlighting = true;
        };
      };
    };
    cmp = {
      enable = true;
      settings = {
        snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
        window = {
          completion.__raw = "cmp.config.window.bordered";
          documentation.__raw = "cmp.config.window.bordered";
        };
      };
    };
    #    telescope = {
    # enable = true;
    # keymaps = {
    # 	"<leader>fg" = "live_grep";
    # };
    #    };
  };
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch";
      cd = "z";
    };
    history = {
      size = 10000;
      path = "$XDG_DATA_HOME/zsh/history";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "robbyrussell";
    };
    initExtra = "bindkey '^ ' autosuggest-execute";
    plugins = [
      {
        # will source zsh-autosuggestions.plugin.zsh
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
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
