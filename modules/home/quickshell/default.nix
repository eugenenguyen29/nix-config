{
  lib,
  config,
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}:
with lib;
let
  cfg = config.shell.quickshell;
  quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.shell.quickshell = {
    enable = mkEnableOption "quickshell";
  };
  config = mkIf cfg.enable {

    programs.quickshell = {
      enable = true;
      package = quickshell;
    };

    home.packages = with pkgs-unstable; [
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qtwayland
      qt6.qtsvg
      qt6.qtmultimedia
    ];

    home.sessionVariables = {
      QML2_IMPORT_PATH = lib.mkDefault "${pkgs-unstable.qt6.qtdeclarative}/lib/qt-6/qml";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };
  };
}
