# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  hyprland,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../gaming/proton-ge.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.cleanOnBoot = true;
  # boot.loader.grub.enable = true;
  #boot.loader.grub.efiSupport = true;
  #boot.loader.grub.efiInstallAsRemovable = true;
  #boot.loader.efi.efiSysMountPoint = "/";
  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only
  # boot.loader.grub.device = "/dev/nvme0n1p1";

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  #CUPS DISABLE
  services.printing.enable = false;
  # Enable networking
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings = {
    Settings = {
      AutoConnect = true;
    };
  };
  networking.networkmanager.wifi.backend = "iwd";
  networking.networkmanager.enable = true;
  # networking.hostName = "joyboy";

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 3d";
  };

  #This specifically allows Spotify to find local files from phone sync
  networking.firewall.allowedTCPPorts = [
    57621
    # 27040
    # 27031
    # 27032
    # 27033
    # 27034
    # 27035
    # 27036
  ];
  zramSwap.enable = true;

  programs.dconf.enable = true;

  #enable caching of art urls
  services.gvfs.enable = true;

  #ollama support
  services.ollama = {
    enable = true;
    # Optional: load models on startup
    loadModels = [ "deepseek-r1:32b-qwen-distill-q8_0" ];
    acceleration = "cuda";
  };

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
  services.sysprof.enable = true;

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;
  system.autoUpgrade = {
    enable = false;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "--no-write-lock-file"
      "-L" # print build logs
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };
  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm = {
    enable = false;
  };
  #enable greetd instead..
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = "ianh";
      };
      default_session = initial_session;
    };
  };
  services.desktopManager.plasma6.enable = false;

  # Enable hyprland
  programs.hyprland = {
    # we use this instead of putting it in systemPackages/users
    enable = true;
    xwayland.enable = true;
  };

  #Enable NVIDIA drivers
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  fonts.packages =
    with pkgs;
    [
      meslo-lgs-nf
      jetbrains-mono
      font-awesome
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      maple-mono
    ]
    ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  # Enable steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;
  #enable VR?
  services.monado = {
    enable = true;
    defaultRuntime = true; # Register as default OpenXR runtime
  };
  programs.envision.enable = true;
  systemd.user.services.monado.environment = {
    STEAMVR_LH_ENABLE = "1";
    XRT_COMPOSITOR_COMPUTE = "1";
    WMR_HANDTRACKING = "0";
    U_PACING_COMP_MIN_TIME_MS = "5";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

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
  services.libinput.mouse.accelPointsMotion = [ 0.0 ];
  services.libinput.mouse.accelPointsFallback = [ 0.0 ];

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  #add nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ianh = {
    isNormalUser = true;
    description = "Ian Huezo";
    extraGroups = [
      "networkmanager"
      "wheel"

    ];
    packages = with pkgs; [
      #  thunderbird
    ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;
  # Install firefox.
  programs.firefox.enable = true;
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  #set the default shells
  environment.shells = with pkgs; [ zsh ];
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    cava
    valgrind
    ripgrep
    libnotify
    inotify-tools
    sysstat
    networkmanagerapplet
    git
    zsh
    nixfmt-rfc-style
    home-manager
    vesktop
    webcord
    gnumake
    gcc
    noisetorch
    protonup
    kitty
    pavucontrol
    dunst
    swaylock-effects
    btop
    wofi
    hyprshot
    playerctl
    dracula-theme
    dracula-icon-theme
    tela-icon-theme
    inputs.swww.packages.${pkgs.system}.swww
    treefmt
    nixfmt-rfc-style
    pulseaudio
    ffmpeg
    (python3.withPackages (
      python-pkgs: with python-pkgs; [
        yt-dlp
	eyed3
	pillow
      ]
    ))
    # glxinfo # Provides glxinfo command
    # mesa-demos # Provides additional OpenGL utilities
  ];
  #add git-lfs for vr stuff
  programs.git.enable = true;
  programs.git.lfs.enable = true;
  environment.sessionVariables = {
    WLR_M__HARDWARE_CUROS = "1";
    NIXOS_OZONE_WL = "1";
  };
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
  system.stateVersion = "24.11"; # Did you read the comment?

}
