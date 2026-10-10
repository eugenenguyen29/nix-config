# nixos-anywhere: password login as a non-root user (e.g. `nixos`)

**Finding.** With `--phases disko,install`, nixos-anywhere (1.13.0) ignores the
user in `--target-host nixos@<ip>` and asks for **root's** password. When the
`kexec` phase is missing, it assumes kexec already ran and rewrites the target
to `root@<host>` before it uploads its key (`nixos-anywhere.sh:985-986`).

**Fix.** Keep the `kexec` phase: `--phases kexec,disko,install`.
- On a target already booted into the NixOS installer, kexec does nothing
  (`runKexec` returns early when `isInstaller == y`, line 700).
- nixos-anywhere then logs in as the given user and asks for that user's password
  once, to upload a temporary key.
- It copies that key to `/root/.ssh` with `sudo` and carries on as root
  (lines 1039-1042). The user therefore needs passwordless sudo, which the
  installer's `nixos` user has by default.
- If the target is *not* the installer, kexec really runs and replaces the OS.

**Related fixes needed for the password prompt to appear:**
1. **SSH agent with many keys.** ssh offers every agent key before trying a
   password. With more than 6 keys, sshd stops with `Too many authentication
   failures`. Add `--ssh-option IdentityAgent=none` (and the same option on any
   follow-up `ssh` calls).
2. **Repeated failures block the client.** OpenSSH's `PerSourcePenalties` refuses
   a client after failed logins; the client sees `kex_exchange_identification:
   Connection reset by peer`. Clear it with `sudo systemctl restart sshd` on the
   target, or wait for the block to expire.
3. **Host key checks.** nixos-anywhere doesn't save the host key
   (`UserKnownHostsFile=/dev/null`). Follow-up `ssh` calls need
   `-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null`, or they stop at
   an unknown-host-key prompt.

**Resulting call.** The `install` recipe in the `justfile` is the source of
truth; it applies every fix above.
