{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.git;
in
{
  options.modules.git = {
    enable = mkEnableOption "Git configuration";
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "Ian Huezo";
          email = "ianhuezo@gmail.com";
        };
        push.autoSetupRemote = true;
      };
    };
  };
}
