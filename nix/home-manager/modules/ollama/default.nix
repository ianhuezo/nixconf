{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.ollama;
in
{
  options.modules.ollama = {
    enable = mkEnableOption "ollama as a manually-started per-user service";

    package = mkOption {
      type = types.package;
      default = pkgs.ollama-cuda;
      defaultText = literalExpression "pkgs.ollama-cuda";
      description = ''
        The ollama build to serve with. Shared by the server and the model
        loader so the closure carries one ollama, not a CUDA build plus a
        stray CPU one.
      '';
    };

    models = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "qwen3.8:27b" ];
      description = ''
        Models pulled when the server starts. Home Manager's ollama module has
        no `loadModels` of its own, so this drives the loader unit below.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Per-user service, so start/stop needs no sudo:
    #
    #   ollama-start / ollama-stop
    #   systemctl --user status ollama
    services.ollama = {
      enable = true;
      inherit (cfg) package;
    };

    # Home Manager defaults the unit into default.target, which would start it
    # at login. Clearing WantedBy leaves the unit fully defined but idle, so
    # nothing reserves VRAM until asked.
    systemd.user.services.ollama.Install.WantedBy = mkForce [ ];

    # Stands in for the NixOS module's `loadModels`: pulls are attached to the
    # server coming up rather than to login. `pull` is a no-op once a model is
    # present, and BindsTo keeps the loader from lingering if ollama stops.
    systemd.user.services.ollama-model-loader = mkIf (cfg.models != [ ]) {
      Unit = {
        Description = "Pull declared ollama models";
        After = [ "ollama.service" ];
        BindsTo = [ "ollama.service" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = toString (
          pkgs.writeShellScript "ollama-load-models" ''
            # `serve` is up before it accepts requests; wait rather than race it.
            until ${cfg.package}/bin/ollama list >/dev/null 2>&1; do sleep 1; done
            ${concatMapStringsSep "\n" (m: "${cfg.package}/bin/ollama pull ${escapeShellArg m}") cfg.models}
          ''
        );
      };
      Install.WantedBy = [ "ollama.service" ];
    };

    programs.zsh.shellAliases = {
      ollama-start = "systemctl --user start ollama";
      ollama-stop = "systemctl --user stop ollama";
    };
  };
}
