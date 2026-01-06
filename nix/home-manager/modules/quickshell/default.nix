{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.quickshell;
  isLinux = pkgs.stdenv.isLinux;
  quickshellPath = /etc/nixos/dotfiles/quickshell;
  hasQuickshell = inputs ? quickshell && inputs.quickshell ? packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.modules.quickshell = {
    enable = mkEnableOption "Option to enable quickshell";
  };

  config = mkIf (cfg.enable && isLinux && hasQuickshell) {
    home.packages = [
      inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.qt6.qtbase
      pkgs.qt6.qtdeclarative
      pkgs.qt6.qtsvg
      pkgs.qt6.qtimageformats
      pkgs.qt6.qtmultimedia
      pkgs.qt6.qt5compat
    ];

    home.file.".config/quickshell".source = config.lib.file.mkOutOfStoreSymlink quickshellPath;

    home.sessionVariables = {
      QS_CONFIG_PATH = "${config.home.homeDirectory}/.config/quickshell";
      QS_BASE_PATH = "${config.home.homeDirectory}/.config/quickshell";
      QML2_IMPORT_PATH = "${pkgs.qt6.qtdeclarative}/${pkgs.qt6.qtbase.qtQmlPrefix}:${
        inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
      }/lib/qt-6/qml:${config.home.homeDirectory}/.config/quickshell";
      QML_IMPORT_PATH = "${config.home.homeDirectory}/.config/quickshell";
      QT_QML_ROOT_PATH = "${config.home.homeDirectory}/.config/quickshell";
    };
  };
}
