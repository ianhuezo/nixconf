{ config, pkgs, nixvim, ... }:

{
  # Import additional packages
#   imports = 
#   [
# 	./plasma.nix
#   ];
#    imports = [
#	./modules/home-programs/zsh	
#    ]
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "ianh";
  home.homeDirectory = "/home/ianh";

  # This value determines the Home Manager release that your configuration is
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
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    zoxide
    zsh
    discord
    kitty
    vesktop
    spotify
  ];
  programs.kitty.enable = true;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
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
	colorschemes.catppuccin.enable = true;
    	plugins.lualine.enable = true;
	plugins.telescope.enable = true;
  };
  programs.zsh = {
	enable = true;
	enableCompletion = true;
	autosuggestion.enable = true;
	syntaxHighlighting.enable = true;

	shellAliases = {
	  ll = "ls -l";
	  update = "sudo nixos-rebuild switch";
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
	plugins = [
		{
			name = "zsh-autosuggestions";
			src = pkgs.fetchFromGitHub {
				owner = "zsh-users";
				repo = "zsh-autosuggestions";
				rev  "v0.4.0";
				sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
			};
		}
	];
  }

  nixpkgs.config.allowUnfree = true; 
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
    XDG_CACHE_HOME = "$HOME/var/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/var/share";
    XDG_STATE_HOME = "$HOME/var/state";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
