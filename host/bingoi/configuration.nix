{ config, pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest; # Zen 5 (9955HX)

  networking.hostName = "bingoi";
  networking.networkmanager.enable = true;
  time.timeZone = "Australia/Sydney";

  # sshd disabled: Tailscale SSH takes over port 22 on the tailnet IP.
  services.openssh.enable = false;
  # Deliberately not importing modules/nixos/tailscale.nix: it trusts all of tailscale0, bingoi only opens 22.
  services.tailscale = {
    enable = true;
    openFirewall = true; # UDP 41641 for direct peer connections
    # Written into /mnt over ssh by `just install`; joins the tailnet on first boot,
    # then deleted by tailscaled-autoconnect below.
    authKeyFile = "/var/lib/tailscale/authkey";
    # Tailscale SSH: tailscaled answers port 22 on the tailnet IP and authenticates
    # via the tailnet policy "ssh" rules.
    extraSetFlags = [ "--ssh" ];
  };
  # Deploys arrive over Tailscale SSH: restarting tailscaled mid-switch kills the
  # session and aborts activation. A changed tailscaled applies on next reboot.
  systemd.services.tailscaled.restartIfChanged = false;
  # One-time key: remove it once the node is Running so the spent key is not left on disk.
  systemd.services.tailscaled-autoconnect.serviceConfig.ExecStartPost =
    "${pkgs.coreutils}/bin/rm -f ${config.services.tailscale.authKeyFile}";
  # Tailscale SSH on the tailnet IP; LAN port 22 stays closed.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  # No password anywhere: login is Tailscale SSH only; console recovery = installer USB.
  users.users.bingoi = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Fallback for when --ssh is turned off / sshd is re-enabled; unused while sshd is off.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPr9t6nVd1x6kxnOpZuxcLIC2x2ciP/gwlK8fZ7OEgNT"
    ];
  };
  security.sudo.wheelNeedsPassword = false;
  security.sudo.execWheelOnly = true;

  services.btrfs.autoScrub.enable = true;
  services.fstrim.enable = true;
  services.power-profiles-daemon.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  # root stays trusted (default trusted-users), so root deploys still connect.
  nix.settings.allowed-users = [ "@wheel" ];
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    git
    vim
    htop

    neovim

    tree

    _1password-cli
  ];

  system.stateVersion = "26.05";
}
