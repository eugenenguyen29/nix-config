{
  lib,
  pkgs,
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
  networking.timeServers = map (n: "${n}.oceania.pool.ntp.org") [
    "0"
    "1"
    "2"
    "3"
  ];
  # Hold tailscaled until NTP has synced. time-sync.target only waits when
  # time-wait-sync is installed (NixOS ships it disabled and ignores [Install]).
  # Timeout so offline boots still start tailscaled (After= is ordering only).
  systemd.additionalUpstreamSystemUnits = [ "systemd-time-wait-sync.service" ];
  systemd.services.systemd-time-wait-sync = {
    wantedBy = [ "sysinit.target" ];
    serviceConfig.TimeoutStartSec = "90s";
  };
  systemd.services.tailscaled.after = [ "time-sync.target" ];

  networking.hostName = vars.host;
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

  time.timeZone = "Australia/Sydney";

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.saber = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ]; # Enable ‘sudo’ for the user.
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

  # Titan Ridge TB3 xHCI (8086:15ec) misses dock hotplug while runtime-suspended:
  # the WD19DC USB3 side (and its RTL8153 NIC) never re-enumerates. Keep it awake.
  # Match bind too: xhci-pci probe calls pm_runtime_allow() for this ID (quirk
  # XHCI_DEFAULT_PM_RUNTIME_ALLOW), which would reset an add-time "on".
  services.udev.extraRules = ''
    ACTION=="add|bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15ec", ATTR{power/control}="on"
  '';

  services.fwupd.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://cache.soopy.moe"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
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

  # First NixOS release installed on this machine. Do not change.
  system.stateVersion = "25.11";
}
