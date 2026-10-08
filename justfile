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
[confirm("install WIPES BOTH disks on the target, including /data. Continue?")]
install host ip:
    #!/usr/bin/env bash
    set -euo pipefail
    test -d host/{{ host }} || { echo "no such host: host/{{ host }}" >&2; exit 1; }
    target="nixos@{{ ip }}"
    # Installer password is typed at the prompts (twice). Agent off: 1Password's many
    # keys would exhaust MaxAuthTries before the password prompt.
    # No host key checks: the installer's host key is ephemeral.
    sshopts=(-o IdentityAgent=none -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

    # No reboot phase: /mnt stays mounted so secrets can be placed before first boot.
    # kexec phase kept: no-op on the installer, but without it nixos-anywhere
    # assumes kexec already ran and logs in as root instead of nixos.
    # Pinned by flake.lock; runs without TS_AUTHKEY in its env.
    nix run --inputs-from . nixos-anywhere -- \
      --ssh-option IdentityAgent=none \
      --phases kexec,disko,install \
      --flake .#{{ host }} \
      --generate-hardware-config nixos-generate-config ./host/{{ host }}/hardware-configuration.nix \
      --target-host "$target"

    # One login: secrets go over stdin from memory, nothing written locally.
    # Only this step sees TS_AUTHKEY; it reaches ssh via env, never argv.
    # shellcheck disable=SC2016 # single quotes intended: expands in op run / remote
    HOST={{ host }} op run --env-file=op.env -- bash -c '
      printf "%s\n" "$TS_AUTHKEY" | ssh "$@"' _ "${sshopts[@]}" "$target" '
      set -e
      mountpoint -q /mnt || { echo "/mnt not mounted; installed system unreachable" >&2; exit 1; }
      read -r authkey
      printf "%s" "$authkey" | sudo install -D -m 600 /dev/stdin /mnt/var/lib/tailscale/authkey'
    echo "Done. Reboot the target: ssh ${sshopts[*]} $target sudo reboot (or umount -R /mnt first)"

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

sync USER HOST:
    rsync -av --filter=':- .gitignore' -e "ssh -l {{ USER }}" . {{ USER }}@{{ HOST }}:nix-config/

sync-secrets USER HOST:
    rsync -av --filter=':- .gitignore' -e "ssh -l {{ USER }}" . {{ USER }}@{{ HOST }}:nix-secrets/
