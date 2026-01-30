{
  config,
  pkgs,
  pkgs-unstable,
  vars,
  lib,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  imports = [
    (import ../../modules/home/neovim/default.nix)
    (import ../../modules/home/git/default.nix)
    ../../modules/home/waybar.nix
  ];
  home = {
    stateVersion = "25.05";
    username = "${toString vars.user}";
    homeDirectory = "${toString vars.home-dir}";
    packages = with pkgs; [
      starship
      bat
      delta
      just
      ncdu
      jq

      obs-studio

      pkgs-unstable.dbeaver-bin
      pkgs-unstable.floorp-bin

      pkgs-unstable.hyprshot
      pkgs-unstable.claude-code
      pkgs-unstable.libreoffice-qt6-fresh

      pkgs-unstable.syncthing

      blender

      uv
      python314
    ];
    shell.enableZshIntegration = true;
    sessionVariables = {
      EDITOR = "${toString vars.editor}";
      HOME_MANAGER = "${pkgs.lib.makeLibraryPath [ pkgs.home-manager ]}";
    };

    file = {
      ".ideavimrc".text = builtins.readFile "${vars.dotfile-path}/.ideavimrc";
      ".config/nvim" = {
        source = mkOutOfStoreSymlink "${vars.dotfile-path}/nvim";
        recursive = true;
      };
      ".config/starship" = {
        source = mkOutOfStoreSymlink "${vars.dotfile-path}/starship";
        recursive = true;
      };
    };

  };

  git.enable = true;
  programs.git = {
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH9ciOGgb5XOllKsWI6EkPiMrvENn+oXFTAxG9QGUjwB";
    };
  };

  programs.fzf = {
    enableZshIntegration = true;
  };

  programs.ssh.extraConfig = ''
    Host *
      IdentityAgent ~/.1password/agent.sock
      SetEnv TERM=xterm-256color

    Host github
      AddKeysToAgent yes
      Hostname github.com
      IdentitiesOnly yes
      IdentityFile ~/.ssh/id_github_ed25519
  '';
  programs.bash = {
    enable = true;
  };
}
