{ pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest; # Zen 5 (9955HX)

  networking.hostName = "bingoi";
  networking.networkmanager.enable = true;
  time.timeZone = "Australia/Sydney";

  # SSH reachable over Tailscale only; LAN port 22 stays closed.
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  services.tailscale = {
    enable = true;
    openFirewall = true; # UDP 41641 for direct peer connections
    # Written into /mnt over ssh by `just install`; joins the tailnet on first boot.
    authKeyFile = "/var/lib/tailscale/authkey";
    # Tailscale SSH: tailscaled answers port 22 on the tailnet IP and authenticates
    # via the tailnet policy "ssh" rules; sshd above no longer sees tailnet logins.
    extraSetFlags = [ "--ssh" ];
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  # No password anywhere: login is Tailscale SSH only; console recovery = installer USB.
  users.users.bingoi = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
  security.sudo.wheelNeedsPassword = false;

  services.btrfs.autoScrub.enable = true;
  services.fstrim.enable = true;
  services.power-profiles-daemon.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [ git vim htop ];

  system.stateVersion = "26.05";
}
