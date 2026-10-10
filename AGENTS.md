Never push without my explicit permission.
Never rebuild nix without explicit permission.

ALWAYS look up documentation first before figuring things out: official docs
(context7, the tool's website), `<tool> --help` / man pages, or the option's
source in nixpkgs. Do not guess flags, options or syntax from memory; cite the
doc you used.

Read [docs/infrastructure.md](docs/infrastructure.md) before changing any NixOS
host. Update it in the same change when the infrastructure changes.
Rules for writing that note:
- The Nix config is the source of truth. Point to the file that declares
  something; never restate its values (addresses, mounts, options, packages).
- Write down only what the config cannot express: facts about the physical
  network and hardware, manual steps, and gotchas with their recovery.
- No secrets and no transient status (what is deployed today, what is pending).

Secrets:
- NEVER write a secret in plain text.
- NEVER read a secret or private key with the op CLI. Declare only its `op://`
  reference, by naming convention (see `op.env`); `op run` resolves it in memory.
- 1Password items per NixOS host:
  - `{machine-name}-machine`: username and password
  - `{machine-name}-ssh-key`: SSH key
