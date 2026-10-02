{
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
    (import ./../../modules/home/git/default.nix)
    (import ./../../modules/home/neovim/default.nix)
    (import ./../../modules/home/wezterm/default.nix)
    (import ./../../modules/home/starship/default.nix)
    (import ./../../modules/home/direnv/default.nix)
    (import ./../../modules/home/zsh/default.nix)
  ];

  xdg.enable = true;
  home = {
    stateVersion = "25.05";
    username = "${toString vars.user}";
    homeDirectory = "${toString vars.home-dir}";
    packages = with pkgs; [
      bat
      lazygit
      delta
      just
      fzf
      ripgrep

      tree-sitter
      nixd
      nixfmt-rfc-style

      iperf

      pkgs-unstable.docker
      pkgs-unstable.docker-compose

      age
      pkgs-unstable.sops

      tree
      ncdu

      # Applications
      pkgs-unstable.thunderbird-latest-unwrapped
      pkgs-unstable.brave
      pkgs-unstable.claude-code
      pkgs-unstable.insomnia
    ];

    sessionVariables = {
      EDITOR = "${toString vars.editor}";
      HOME_MANAGER = "${pkgs.lib.makeLibraryPath [ pkgs.home-manager ]}";
    };
    shell.enableZshIntegration = true;
  };

  git.enable = true;
  programs.git = {
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsTUWula6xGju3x3LyEJKxhYDW2BfLvt3wcIjVyY3hC dinhnhattai.nguyen@hotmail.com";
    };
  };

  programs.zoxide = {
    package = pkgs.zoxide;
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    package = pkgs.eza;
    enable = true;
    enableZshIntegration = true;
    icons = "always";
    git = true;
    colors = "always";
    extraOptions = [
      "-a"
      "--group-directories-first"
      "--long"
      "--accessed"
      "--no-time"
    ];
  };

  terminal.wezterm.enable = true;
  shell.zsh.enable = true;
  terminal.starship.enable = true;

  home.file = {
    ".ideavimrc".text = builtins.readFile "${vars.dotfile-path}/.ideavimrc";
    ".config/eza".source = "${vars.dotfile-path}/eza";
    starship = {
      text = builtins.readFile "${vars.dotfile-path}/starship/starship.toml";
      target = "starship.toml";
    };
  };

  xdg.configFile = {
    nvim = {
      source = mkOutOfStoreSymlink "${vars.dotfile-path}/nvim";
    };

    # wezterm = {
    #   source = mkOutOfStoreSymlink "${vars.dotfile-path}/wezterm";
    #   recursive = true;
    # };
  };
}
