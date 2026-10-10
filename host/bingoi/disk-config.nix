# Minisforum MS-A2. A reinstall (nixos-anywhere / disko) wipes BOTH disks, including /data.
# /data stays in disko on purpose; back it up before reinstalling.
# by-id paths: nvme0n1/nvme1n1 can swap between boots.
{
  disko.devices.disk = {
    # Intel 512GB: OS
    system = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-INTEL_SSDPEKNU512GZ_PHKA1216015N512A";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@swap" = {
                  mountpoint = "/.swapvol";
                  swap.swapfile.size = "8G";
                };
              };
            };
          };
        };
      };
    };

    # Kingston 1TB: data
    data = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-KINGSTON_OM8TAP41024K1-A00_50026B73844B7824";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@data" = {
                mountpoint = "/data";
                mountOptions = [ "compress=zstd" "noatime" "nofail" "nodev" "nosuid" ];
              };
              # Incus pool (incus.nix). No nodev/nosuid: container rootfs needs both.
              "@incus" = {
                mountpoint = "/data/incus";
                mountOptions = [ "compress=zstd" "noatime" "nofail" ];
              };
            };
          };
        };
      };
    };
  };
}
