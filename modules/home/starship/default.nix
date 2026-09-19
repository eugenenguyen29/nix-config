{
  config,
  pkgs-unstable,
  vars,
  lib,
  ...
}:
let
  cfg = config.terminal.starship;
in
{
  options.terminal.starship = {
    enable = lib.mkEnableOption "StarShip Prompt ";
  };
  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      package = pkgs-unstable.starship;
      enableInteractive = true;
      enableZshIntegration = true;
    };
    home.file = {
      ".config/starship" = {
        source = config.lib.file.mkOutOfStoreSymlink "${vars.dotfile-path}/starship";
      };
    };
  };
}
