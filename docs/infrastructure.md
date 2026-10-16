# Infrastructure

Index of the machines, plus the facts the Nix config cannot express.
The config is the source of truth: follow the pointers, do not restate them here.

## Hosts

Every host is an output of `flake.nix`. Its `default.nix` holds the module list,
the root of its import graph; follow the `imports` from there. Shared modules
live in `machines/` (hardware profiles) and `modules/` (nixos, home, darwin).
In the table, a bare file name sits next to the host's entry file.

| Host | Kind | Hardware | Entry | Also read |
|------|------|----------|-------|-----------|
| `saber` | NixOS workstation, deploys start here | T2 MacBook | `host/saber/default.nix` | `omarchy.nix`, `machines/t2-mac/`, `machines/laptop/` |
| `bingoi` | NixOS server, Tailscale SSH only | Minisforum MS-A2 | `host/bingoi/default.nix` | `disk-config.nix` (disks, mounts), `incus.nix` |
| `xucxich` | NixOS server, VLAN bridges, podman | | `host/xucxich/default.nix` | `incus.nix` |
| `popcorn` | NixOS desktop (omarchy) | PC | `host/popcorn/default.nix` | `omarchy.nix` |
| `imbp` | nix-darwin | Intel Mac | `host/imbp/default.nix` | `packages.nix`, `darwin/`, `modules/darwin/` |

Deploy and install: recipes in the `justfile`, `scripts/`,
`docs/nixos-anywhere.md`.

## Reading a host's state

Files show what one module sets; the evaluated config shows the merged result,
defaults and every other module included. Ask the evaluator before trusting a
reading of the files. Evaluating builds nothing and changes no host.

```bash
nix flake show                                             # every host output
nix eval .#nixosConfigurations.<host>.config.<option>      # one merged option
nix eval --json .#nixosConfigurations.<host>.config.environment.systemPackages \
  --apply 'map (p: p.name)'                                # system packages
nix eval .#darwinConfigurations.imbp.config.<option>       # darwin host
```

A host that fails to evaluate is broken in the repo; report it before changing it.

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
