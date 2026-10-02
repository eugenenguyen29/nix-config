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

      pkgs-unstable.floorp-bin

      pkgs-unstable.claude-code
      pkgs-unstable.docker-buildx
      pkgs-unstable.libreoffice-qt6-fresh
      pkgs-unstable.tor-browser
    ];

    sessionVariables = {
      EDITOR = "${toString vars.editor}";
      HOME_MANAGER = "${pkgs.lib.makeLibraryPath [ pkgs.home-manager ]}";
    };

    file = {
      ".ideavimrc".text = builtins.readFile "${vars.dotfile-path}/.ideavimrc";
      ".config/nvim" = {
        source = mkOutOfStoreSymlink "${vars.dotfile-path}/nvim";
      };
    };

  };

  git.enable = true;
  programs.git = {
    signing = lib.mkForce {
      signByDefault = false;
      format = "ssh";
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMKfuyuHdyTNrtlNAcd3ychG6mVQOAUZu15za7KNMQWD dinhnhattai.nguyen@hotmail.com";
    };
  };

  programs.ssh.extraConfig = ''
    Host github
    AddKeysToAgent yes
    Hostname github.com
    IdentitiesOnly yes
    IdentityFile ~/.ssh/id_github_ed25519
  '';

  wayland.windowManager.hyprland.settings = {
    input.kb_options = lib.mkForce "caps:swapescape, altwin:swap_alt_win";
  };

  programs.bash = {
    enable = true;
  };
}
