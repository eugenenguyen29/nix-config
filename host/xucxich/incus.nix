{
  lib,
  pkgs,
  ...
}:
{

  virtualisation.incus = {
    enable = true;
    ui.enable = true;

    # Use btrfs storage backend (partition mounted at /var/lib/incus)
    preseed = {
      networks = [
        {
          name = "incusbr0";
          type = "bridge";
          config = {
            "ipv4.address" = "10.10.10.1/24";
            "ipv4.nat" = "true";
            "ipv6.address" = "none";
          };
        }
      ];

      storage_pools = [
        {
          name = "default";
          driver = "btrfs";
          config = {
            source = "/var/lib/incus/storage-pools/default";
          };
        }
      ];

      profiles = [
        {
          name = "default";
          devices = {
            eth0 = {
              name = "eth0";
              network = "incusbr0";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              type = "disk";
            };
          };
        }
        {
          name = "vlan100";
          devices = {
            eth0 = {
              name = "eth0";
              network = "vlan100br";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              type = "disk";
            };
          };
        }
      ];
    };
  };

  # Add user to incus-admin group
  users.users.xucxich.extraGroups = [ "incus-admin" ];

  # Networking: allow Incus bridge traffic
  networking.firewall.trustedInterfaces = [
    "incusbr0"
    "vlan100br"
  ];
}
