# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  inputs,
  lib,
  pkgs,
  pkgs-unstable,
  vars,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./omarchy.nix
    ../../machines/laptop/default.nix
    ../../machines/t2-mac/default.nix
    ../../modules/nixos/tailscale.nix
  ];

  hardware.apple-t2.kernelChannel = "stable";

  # Docked lid close -> external monitors only (logind: machines/laptop).
  omarchy.lid.enable = true;

  # Cap disk usage of logs and crash dumps.
  services.journald.extraConfig = "SystemMaxUse=200M";
  systemd.coredump.settings.Coredump.MaxUse = "200M";

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.efiSysMountPoint = "/boot";
    efi.canTouchEfiVariables = true;
  };
  # RTC resets to 1970 on this Mac. Loaded late, rtc_cmos overwrites the clock
  # systemd/timesyncd already restored -> TLS fails, tailscale exit node is dead
  # and blackholes all traffic (incl. NTP). Load it first so the restore wins.
  boot.initrd.kernelModules = [ "rtc_cmos" ];
  networking.timeServers = map (n: "${n}.oceania.pool.ntp.org") [ "0" "1" "2" "3" ];
  # Hold tailscaled until NTP has synced. time-sync.target only waits when
  # time-wait-sync is installed (NixOS ships it disabled and ignores [Install]).
  # Timeout so offline boots still start tailscaled (After= is ordering only).
  systemd.additionalUpstreamSystemUnits = [ "systemd-time-wait-sync.service" ];
  systemd.services.systemd-time-wait-sync = {
    wantedBy = [ "sysinit.target" ];
    serviceConfig.TimeoutStartSec = "90s";
  };
  systemd.services.tailscaled.after = [ "time-sync.target" ];

  networking.hostName = "${vars.host}"; # Define your hostname.
  # networking.extraHosts = builtins.readFile "${vars.home-dir}/.config/extrahosts";
  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };

  networking.wireless.iwd = {
    enable = true;
    settings = {
      IPv6 = {
        Enable = false;
      };
      Settings = {
        AutoConnect = true;
      };
    };
  };
  # Set your time zone.
  time.timeZone = "Australia/Sydney";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = [
      pkgs-unstable.ibus-engines.bamboo
    ];
  };

  environment.sessionVariables = {
    GTK_IM_MODULE = "ibus";
    QT_IM_MODULE = "ibus";
    XMODIFIERS = "@im=ibus";
    INPUT_METHOD = "ibus";
    SDL_IM_MODULE = "ibus";

    NIIXOS_OZONE_WL = "1";
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.saber = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
    shell = pkgs.zsh;
  };

  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    # compinit here runs before home-manager extends fpath, so the dump never
    # matches and gets rebuilt every shell (~3s). home-manager/omarchy run it.
    enableGlobalCompInit = false;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # docker group == passwordless root; run the daemon as the user instead.
  virtualisation.docker.enable = lib.mkForce false;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # LLMNR is spoofable on untrusted networks; mDNS covers .local.
  services.resolved.settings.Resolve.LLMNR = "false";

  services.fwupd.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # programs.firefox.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    neovim
    git

    just
  ];

  programs.ssh.startAgent = true;
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;

      substituters = [
        "https://cache.soopy.moe"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];

      trusted-substituters = [
        "https://cache.soopy.moe"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 5d";
      dates = "weekly";
    };
    optimise.automatic = true;
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
}
