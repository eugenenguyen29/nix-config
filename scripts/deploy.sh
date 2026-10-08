#!/usr/bin/env bash
# Apply a NixOS config to a remote host, building on the host itself.
# Usage: deploy.sh HOST [MODE=switch|test|boot] [USER=root]
set -euo pipefail

host=$1
mode=${2:-switch}
user=${3:-root}

sudo=()
[[ $user != root ]] && sudo=(--ask-sudo-password)

# nix run: works from hosts without nixos-rebuild on PATH (darwin).
nix run nixpkgs#nixos-rebuild -- "$mode" \
  --flake ".#$host" \
  --target-host "$user@$host" \
  --build-host "$user@$host" \
  --fallback \
  "${sudo[@]}"
