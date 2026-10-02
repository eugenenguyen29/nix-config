{ config, lib, vars, pkgs-unstable, ... }:

with lib;
let
  cfg = config.terminal.wezterm;
  inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  options.terminal.wezterm = { enable = mkEnableOption "Wezterm"; };
  config = mkIf cfg.enable {

    programs.wezterm = {
      enable = true;
      package = pkgs-unstable.wezterm;
      enableZshIntegration = true;
    };

    home.file = {
      ".config/wezterm" = {
        source = mkOutOfStoreSymlink "${vars.dotfile-path}/wezterm";
      };
    };
  };
}
