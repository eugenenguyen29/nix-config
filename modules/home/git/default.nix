{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  name = "Moritz Zimmerman";
  email = "dinhnhattai.nguyen@hotmail.com";
  cfg = config.git;
in
{
  options.git = {
    enable = mkEnableOption "Git";
  };
  config = mkIf cfg.enable {
    programs.git = mkForce {
      enable = true;
      package = pkgs.git;
      maintenance.enable = true;
      settings = {
        user.name = name;
        user.email = email;
        branch.autosetuprebase = "always";
        color.ui = true;
        github.user = "JustinHammer-teck";
        push.default = "tracking";
        rerere.enabled = true;
        init.defaultBranch = "master";
        alias = {
          gsw = "git switch";
          prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        };
        gpg = {
          format = "ssh";
          ssh.program = "${pkgs._1password-gui}/share/1password/op-ssh-sign";
        };

      };
      signing = {
        signByDefault = true;
      };
      ignores = [
        ".DS_Store"
        "node_modules"
        ".direnv"
        "result"
      ];
    };
  };
}
