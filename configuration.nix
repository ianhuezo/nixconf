# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "joyboy"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  #add nix settings
  nix.settings = {
	experimental-features = [ "nix-command" "flakes" ];
	allowed-users = [
	  "*"
	];
  };
  
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ianh = {
    isNormalUser = true;
    description = "Ian Huezo";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;


#  #Home manager settings
#  home-manager.users.ianh = { pkgs, ... }: {
#  	home.packages = with pkgs; [ 
#		zoxide
#		thefuck
#		zsh #home manager can't set zsh as a shell directly because of root permissions for shell
#		discord
#		spotify
#		vesktop
#	];
#
#
#	home.sessionVariables = {
#		    XDG_CACHE_HOME = "$HOME/var/.cache";
#                    XDG_CONFIG_HOME = "$HOME/.config";
#                    XDG_DATA_HOME = "$HOME/var/share";
#                    XDG_STATE_HOME = "$HOME/var/state";	
#	};
#	home.stateVersion = "24.05";
#	home.homeDirectory = "/home/ianh";
#	
#	programs.home-manager = {
#		enable = true;
#	};
#	programs.zsh = {
#	 	enable = true;
#	 	enableCompletion = true;
#                 autosuggestion.enable = true;
#                 syntaxHighlighting.enable = true;
#
#                 shellAliases = {
#                   ll = "ls -l";
#                   update = "sudo nixos-rebuild switch";
#                 };
#                 history = {
#                   size = 10000;
#                   path = "$XDG_DATA_HOME/zsh/history";
#                 };
#
#                 oh-my-zsh = {
#                     enable = true;
#                     plugins = [ "git" ];
#                     theme = "robbyrussell";
#                 };
#	 	plugins = [
#	 	   {
#                      name = "zsh-autosuggestions";
#                      src = pkgs.fetchFromGitHub {
#                        owner = "zsh-users";
#                        repo = "zsh-autosuggestions";
#                        rev = "v0.4.0";
#                        sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
#                      };
#                    }
#	 	];
#	 };
#  };
#  home-manager.useUserPackages = true;
#  home-manager.useGlobalPkgs = true;

  # Install firefox.
  programs.firefox.enable = true;
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  #set the default shells
  environment.shells = with pkgs; [zsh];
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
     git
     zsh
     nixfmt-rfc-style
     home-manager
     vesktop
     gnumake
     gcc
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
