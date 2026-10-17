Push or rebuild nix only after I explicitly say so.

Look up documentation before acting: official docs (context7, the tool's
website), `<tool> --help` / man pages, or the option's source in nixpkgs.
Cite the doc you used.

Read [docs/infrastructure.md](docs/infrastructure.md) before inspecting or
changing any host. Update it in the same change when the infrastructure
changes, following the writing rules in its header.

Secrets live in 1Password. Declare only an `op://` reference in `op.env`
(naming convention in its header); `op run` resolves it in memory. Never write
a secret in plain text, and never read a secret or private key with the op CLI.
