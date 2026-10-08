#!/usr/bin/env bash
# Apply a NixOS config to a remote host, building on the host itself.
# Usage: deploy.sh HOST [MODE=switch|test|boot] [USER=root]
set -euo pipefail

host=${1:?usage: deploy.sh HOST [switch|test|boot] [USER]}
mode=${2:-switch}
user=${3:-root}

# Non-root: passwordless sudo (wheel) for activation.
sudo=()
[[ $user != root ]] && sudo=(--sudo)

# nix run: works from hosts without nixos-rebuild on PATH (darwin).
# --no-reexec: use this pinned nixos-rebuild, not the target's.
nix run nixpkgs#nixos-rebuild -- "$mode" \
  --flake ".#$host" \
  --target-host "$user@$host" \
  --build-host "$user@$host" \
  --fallback \
  --no-reexec \
  ${sudo[@]+"${sudo[@]}"}
