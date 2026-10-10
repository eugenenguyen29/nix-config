{
  virtualisation.incus = {
    enable = true;

    preseed = {
      networks = [
        {
          name = "incusbr0";
          type = "bridge";
          config = {
            # Not 10.10.10.0/24 as on xucxich: that is the real VLAN 100 subnet here.
            "ipv4.address" = "10.20.0.1/24";
            "ipv4.nat" = "true";
            "ipv6.address" = "none";
          };
        }
      ];

      # Existing btrfs subvolume on the Kingston 1TB (@incus in disk-config.nix).
      storage_pools = [
        {
          name = "default";
          driver = "btrfs";
          config.source = "/data/incus";
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
        # Instances directly on VLAN 100 (10.10.10.0/24): Incus tags on top of the LAN NIC.
        # macvlan: host and instance cannot talk to each other over this NIC.
        {
          name = "vlan100";
          devices = {
            eth0 = {
              name = "eth0";
              nictype = "macvlan";
              parent = "enp3s0";
              vlan = "100";
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

  # Required by the incus module: iptables is unsupported.
  networking.nftables.enable = true;
  # DHCP/DNS from instances to the host.
  networking.firewall.trustedInterfaces = [ "incusbr0" ];

  users.users.bingoi.extraGroups = [ "incus-admin" ];
}
