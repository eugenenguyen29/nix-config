{
  config,
  inputs,
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
    username = vars.user;
    homeDirectory = vars.home-dir;
    packages = with pkgs; [
      bat
      delta
      just
      ncdu
      jq
      tree

      pkgs-unstable.localsend
      pkgs-unstable.dbeaver-bin
      pkgs-unstable.jetbrains.rider

      pkgs-unstable.libreoffice-qt-stable

      thunderbird

      pkgs-unstable.syncthing

      python314

      pkgs-unstable.hyprshot
      hyprland-qt-support

      incus
      virt-viewer

      bitwarden-desktop

      pkgs-unstable.rtk
      pkgs-unstable.cliproxyapi
      pkgs-unstable.claude-code

      pkgs-unstable.uv
      pkgs-unstable.ty
      pkgs-unstable.ruff
    ];
    shell.enableZshIntegration = true;
    sessionVariables = {
      EDITOR = vars.editor;
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

  programs.bash = {
    enable = true;
  };

  programs.floorp = {
    enable = true;
    package = pkgs-unstable.floorp-bin;
    profiles.default = {
      # Existing profile folder in ~/.floorp, keeps current browsing data.
      path = "2084qmzh.default";
      isDefault = true;
      preConfig = builtins.readFile "${inputs.arkenfox}/user.js";
      # Overrides for arkenfox; written after preConfig, so these win.
      settings = { };
    };
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
