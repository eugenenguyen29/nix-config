SOPS_FILE := "secrets.yaml"

# default recipe to display help information
default:
    @just --list

generations:
    sudo nix-env --profile /nix/var/nix/profiles/system --list-generations

rebuild-pre:
    just update-nix-secrets
    git add *.nix

rebuild-post:
    just check-sops

update:
    nix flake update

# Apply config to a remote host (mode: switch | test | boot)
deploy host mode="switch" user="root":
    bash ./scripts/deploy.sh {{ host }} {{ mode }} {{ user }}

# Fresh network install via nixos-anywhere. WIPES the disks in host/<host>/disk-config.nix.
# Target must be booted into the NixOS installer. Secrets: see op.env.
install host ip:
    HOST={{ host }} op run --env-file=op.env -- just _install {{ host }} {{ ip }}

_install host ip:
    #!/usr/bin/env bash
    set -euo pipefail
    target="nixos@{{ ip }}"
    # Installer password is typed at the prompts (twice). Agent off: 1Password's many
    # keys would exhaust MaxAuthTries before the password prompt.
    sshopts=(-o IdentityAgent=none -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

    # No reboot phase: /mnt stays mounted so secrets can be placed before first boot.
    # kexec phase kept: no-op on the installer, but without it nixos-anywhere
    # assumes kexec already ran and logs in as root instead of nixos.
    nix run github:nix-community/nixos-anywhere -- \
      --ssh-option IdentityAgent=none \
      --phases kexec,disko,install \
      --flake .#{{ host }} \
      --generate-hardware-config nixos-generate-config ./host/{{ host }}/hardware-configuration.nix \
      --target-host "$target"

    # One login: secrets go over stdin from memory, nothing written locally.
    printf '%s\n' "$TS_AUTHKEY" | ssh "${sshopts[@]}" "$target" '
      set -e
      mountpoint -q /mnt || { echo "/mnt not mounted; installed system unreachable" >&2; exit 1; }
      read -r authkey
      printf "%s" "$authkey" | sudo install -D -m 600 /dev/stdin /mnt/var/lib/tailscale/authkey'

rebuild-darwin:
    ./scripts/darwin-rebuild.sh

rebuild $host *ARG:
    bash ./scripts/nixos-rebuild.sh {{ host }} {{ ARG }}

rebuild-update $host:
    just update
    just rebuild  {{ host }}

clean:
    nix-env --delete-generations +3 -p /nix/var/nix/profiles/system
    nix-collect-garbage --delete-older-than 7d

brew-up:
    brew upgrade --greedy

diff:
    git diff ':!flake.lock'

sops:
    echo "Editing {{ SOPS_FILE }}"
    nix-shell -p sops --run "SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops {{ SOPS_FILE }}"

age-key:
    nix-shell -p age --run "age-keygen"

rekey:
    cd ../nix-secrets && (\
      sops updatekeys -y secrets.yaml && \
      (pre-commit run --all-files || true) && \
      git add -u && (git commit -m "chore: rekey" || true) && git push \
    )

check-sops:
    scripts/check-sops.sh

update-nix-secrets:
    (cd ../nix-secrets && git fetch && git rebase) || true
    nix flake lock --update-input nix-secrets

iso:
    # If we dont remove this folder, libvirtd VM doesnt run with the new iso...
    rm -rf result
    nix build ./nixos-installer#nixosConfigurations.iso.config.system.build.isoImage

iso-install DRIVE:
    just iso
    sudo dd if=$(eza --sort changed result/iso/*.iso | tail -n1) of={{ DRIVE }} bs=4M status=progress oflag=sync

disko DRIVE PASSWORD:
    echo "{{ PASSWORD }}" > /tmp/disko-password
    sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
      --mode disko \
      disks/btrfs-luks-impermanence-disko.nix \
      --arg disk '"{{ DRIVE }}"' \
      --arg password '"{{ PASSWORD }}"'
    rm /tmp/disko-password

sync USER HOST:
    rsync -av --filter=':- .gitignore' -e "ssh -l {{ USER }}" . {{ USER }}@{{ HOST }}:nix-config/

sync-secrets USER HOST:
    rsync -av --filter=':- .gitignore' -e "ssh -l {{ USER }}" . {{ USER }}@{{ HOST }}:nix-secrets/
