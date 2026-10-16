# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  vars,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/virtualisation
    ./omarchy.nix
    ../../modules/nixos/fonts.nix
  ];

  omarchy.hyprlock_wallpaper = lib.mkForce ../../assets/wallpapers/needing-space.jpg;

  services.virtualisation.podman.enable = false;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  security.pam.sshAgentAuth.enable = true;

  networking.hostName = "popcorn";
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  networking.firewall = {
    enable = false;

    trustedInterfaces = [
      "tailscale0"
      "enp2s0"
    ];

    allowedTCPPorts = [
      22
    ];

    allowedUDPPorts = [
      53
      config.services.tailscale.port
    ];
  };

  time.timeZone = "Australia/Sydney";

  users.users.moritzzmn = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
      "incus-admin"
    ];
    packages = with pkgs; [
      tree
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILqP1HvcppNVOVZn/B3hd6He1ibPsTisvL16su7k9/7k moritzzmn@imbp"
    ];
  };

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    curl

    localsend
    tmux

    pkgs-unstable.thunderbird-latest
    pkgs-unstable.vscodium

    pkgs-unstable.jetbrains.pycharm
    pkgs-unstable.jetbrains.rider
  ];

  services.openssh = {
    enable = true;
    allowSFTP = false;
    ports = [ 22 ];

    settings = {
      LogLevel = "INFO";
      AllowUsers = [ "moritzzmn" ];
      PasswordAuthentication = true;
      X11Forwarding = false;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
    };

    extraConfig = ''
      PubkeyAuthentication yes

      ClientAliveCountMax 10
      ClientAliveInterval 300

      AllowTcpForwarding yes
      AllowAgentForwarding no
      TCPKeepAlive yes
    '';
  };

  services.tailscale = {
    enable = true;
    package = pkgs-unstable.tailscale;
    openFirewall = true;
  };

  nix = {
    settings = {
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 5d";
      dates = "weekly";
    };
    optimise.automatic = true;
  };
  boot.loader.systemd-boot.configurationLimit = 3;
  # OR for GRUB:
  # boot.loader.grub.configurationLimit = 3;
  nix.settings.auto-optimise-store = true;

  system.stateVersion = "25.11"; # Did you read the comment?
}
