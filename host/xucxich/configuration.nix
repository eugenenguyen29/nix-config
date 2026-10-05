# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./incus.nix
    ../../modules/nixos/virtualisation
  ];

  services.virtualisation.podman.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking = {
    nftables.enable = true;
    hostName = "xucxich";
    tempAddresses = "disabled";
    useDHCP = false;
    vlans = {
      eno2-vlan100 = {
        id = 100;
        interface = "eno2";
      };
    };
    bridges = {
      inbr0 = {
        interfaces = [ "eno2" ];
      };
      vlan100br = {
        interfaces = [ "eno2-vlan100" ];
      };
    };
    interfaces = {
      inbr0 = {
        useDHCP = true;
        macAddress = "a6:3f:8a:0e:bf:19";
      };
      vlan100br = {
        useDHCP = true;
      };
    };
  };
  networking.networkmanager.enable = false; # Disabled - using scripted networking for bridge

  systemd.coredump.enable = false;
  services.openssh = {
    enable = true;
    allowSFTP = false;
    ports = [ 22 ];

    settings = {
      LogLevel = "INFO";
      AllowUsers = [ "xucxich" ];
      PasswordAuthentication = true;
      X11Forwarding = false;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
    };

    extraConfig = ''
      PubkeyAuthentication yes
      ClientAliveInterval 300

      AllowTcpForwarding yes
      AllowAgentForwarding no
      MaxAuthTries 3
      TCPKeepAlive yes
    '';
  };

  security.pam.sshAgentAuth.enable = true;
  networking.firewall = {
    enable = true;

    trustedInterfaces = [
      "tailscale0"
      "inbr0"
      "vlan100br" # NixOS-managed bridge for VLAN 100
    ];

    allowedTCPPorts = [ 22 ];

    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  time.timeZone = "Australia/Sydney";

  users = {
    users.xucxich = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
        "podman"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILqP1HvcppNVOVZn/B3hd6He1ibPsTisvL16su7k9/7k moritzzmn@imbp"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.

    pkgs-unstable.neovim

    wget
    curl

    git
    tree
    just

    pkgs-unstable.butane

    btop
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 15d";
    };
    optimise.automatic = true;
  };

  services = {
    tailscale = {
      enable = true;
      package = pkgs-unstable.tailscale;
      extraSetFlags = [
        "--advertise-exit-node"
        "--advertise-routes=10.10.20.0/24"
      ];
      extraUpFlags = [ "--ssh" ];
      useRoutingFeatures = "both";
    };
  };

  services.tuned = {
    enable = true;
    ppdSupport = true; # Enable tuned-ppd for automatic AC/battery profile switching
    settings.dynamic_tuning = true; # Monitor workload and adjust settings dynamically
  };

  system.stateVersion = "25.11"; # Did you read the comment?
}
