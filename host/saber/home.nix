{
  inputs,
  config,
  pkgs,
  pkgs-unstable,
  vars,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  imports = [
    ../../modules/home/neovim/default.nix
    ../../modules/home/git/default.nix
    ../../modules/home/starship/default.nix
  ];
  home = {
    stateVersion = "25.05";
    username = "${toString vars.user}";
    homeDirectory = "${toString vars.home-dir}";
    packages = with pkgs; [
      bat
      delta
      just
      ncdu
      jq
      virt-viewer

      pkgs-unstable.localsend
      pkgs-unstable.dbeaver-bin
      pkgs-unstable.jetbrains.rider

      pkgs-unstable.floorp-bin
      pkgs-unstable.libreoffice-qt-stable

      thunderbird

      pkgs-unstable.claude-code

      pkgs-unstable.syncthing

      pkgs-unstable.odin

      uv
      python314

      tmux
      usbimager

      pkgs-unstable.hyprshot
      hyprland-qt-support

      sops
      age

      virt-viewer
      incus

      bitwarden-cli
      bitwarden-desktop

      pkgs-unstable.rtk
    ];
    shell.enableZshIntegration = true;
    sessionVariables = {
      EDITOR = "${toString vars.editor}";
      HOME_MANAGER = "${pkgs.lib.makeLibraryPath [ pkgs.home-manager ]}";
    };

    file = {
      ".ideavimrc".source = mkOutOfStoreSymlink "${vars.dotfile-path}/.ideavimrc";
      ".config/nvim" = {
        source = mkOutOfStoreSymlink "${vars.dotfile-path}/nvim";
      };
    };
  };

  git.enable = true;
  terminal.starship.enable = true;
  programs.git = {
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH9ciOGgb5XOllKsWI6EkPiMrvENn+oXFTAxG9QGUjwB";
    };
  };

  # omarchy-nix's zsh module already runs compinit; don't run it a second time.
  programs.zsh.completionInit = "";

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

  programs.atuin = {
    enable = true;
    package = pkgs-unstable.atuin;
    settings = {
      auto_sync = false;
      update_check = false;
      search_mode = "prefix";
    };
    enableZshIntegration = true;
  };
}
