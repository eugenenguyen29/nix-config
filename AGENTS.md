Never push without my explicit permission.
Never rebuild nix without explicit permission.

ALWAYS look up documentation first before figuring things out: official docs
(context7, the tool's website), `<tool> --help` / man pages, or the option's
source in nixpkgs. Do not guess flags, options or syntax from memory; cite the
doc you used.

NEVER use plain text for secret use op cli to get the value
for nixos host:
{machine-name}-machine : stored username and password info
{machine-name}-ssh-key : stored ssh information 

NEVER reach secret or private key from op cli
You MUST only declare via naming convention only.
