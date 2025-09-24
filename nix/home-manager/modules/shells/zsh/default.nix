{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.zsh;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  options.modules.zsh = {
    enable = mkEnableOption "Enable zsh for shell";
  };

  config = mkIf cfg.enable {
    # Install dependencies
    home.packages =
      with pkgs;
      [
        eza
        zoxide
        zsh
        starship
        krabby
      ]
      ++ optionals isLinux [
        fastfetch
      ];
    programs.starship = {
      enable = true;
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        ll = "eza -la";
        lt = "eza --tree";
        ls = "eza";
        update = "sudo nixos-rebuild switch --flake .#joyboy";
        nixfmt = "sudo nixfmt";
        cd = "z";
      };

      history = {
        size = 10000;
        save = 10000;
        path = "${config.home.homeDirectory}/.config/zsh/history";
      };

      initContent = ''
        bindkey '^ ' autosuggest-execute
        fastfetch
      '';

      plugins = [
        {
          name = "zsh-autosuggestions";
          src = pkgs.fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-autosuggestions";
            rev = "v0.7.1";
            sha256 = "sha256-vpTyYq9ZgfgdDsWzjxVAE7FZH4MALMNZIFyEOBLm5Qo=";
          };
        }
      ];
    };

    # Enable zoxide (for the 'z' command)
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
