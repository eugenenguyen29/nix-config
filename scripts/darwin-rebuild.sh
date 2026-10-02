sudo nix run nix-darwin/nix-darwin-25.11#darwin-rebuild -- \
    switch --flake \
    .#imbp --impure --fallback --show-trace
