# Infrastructure

Index of the NixOS machines, plus the facts the Nix config cannot express.
The config is the source of truth: follow the pointers, do not restate them here.

## Hosts

| Host | Start here | For |
|------|------------|-----|
| `saber` | `host/saber/configuration.nix` | Workstation; deploys start here. |
| `bingoi` | `host/bingoi/configuration.nix` | Access, firewall, Tailscale SSH. |
| | `host/bingoi/disk-config.nix` | Disks, subvolumes, mounts. |
| | `host/bingoi/incus.nix` | Incus pool, bridge, profiles. |
| `xucxich` | `host/xucxich/configuration.nix` | VLAN and bridge interfaces, podman. |
| | `host/xucxich/incus.nix` | Incus pool, bridge, profiles. |
| `popcorn` | `host/popcorn/configuration.nix` | |

Deploy and install: `deploy` and `install` recipes in the `justfile`,
`scripts/deploy.sh`, `docs/nixos-anywhere.md`.

## Outside the config

Facts about the physical network. Nothing in this repo declares them.

- `192.168.10.0/24` is the untagged LAN.
- `10.10.10.0/24` is a real network on VLAN 100 (tagged). Do not use that range
  for a private bridge on a host that can reach VLAN 100.
- An instance on bingoi's `vlan100` Incus profile only gets a lease if the switch
  port behind `enp3s0` carries VLAN 100 tagged.

## Gotchas

- **disko only acts at install time.** On an installed host, a rebuild turns
  `disk-config.nix` into mount entries and nothing else: it never formats,
  partitions or creates subvolumes. Create a newly declared subvolume by hand on
  the host before deploying. NixOS has no `/mnt`, so mount on a temporary
  directory:

  ```bash
  d=$(mktemp -d)
  sudo mount -o subvolid=5 /dev/disk/by-partlabel/<label> "$d"
  sudo btrfs subvolume create "$d/@name"
  sudo umount "$d"
  ```

- **A deploy cut off by its own SSH session.** Deploys to bingoi travel over
  Tailscale SSH. If activation restarts `tailscaled`, the session dies and
  `switch-to-configuration` aborts halfway: `/run/current-system` is the new
  generation, but new units are not started. `nixos-rebuild` then prints a
  misleading `did you forget to use --ask-sudo-password?`. The guard is in
  `host/bingoi/configuration.nix` (`restartIfChanged`). To recover, run the same
  deploy again; it finishes the pending unit starts.
