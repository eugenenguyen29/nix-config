{
  description = "Nix, NixOS and Nix Darwin System Flake Configuration";

  nixConfig = {
    extra-substituters = [
      "https://cache.soopy.moe"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11"; # Nix Packages (Default)
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable"; # Unstable Nix Packages
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    felixkratz-formulae = {
      url = "github:FelixKratz/homebrew-formulae";
      flake = false;
    };

    omarchy-nix = {
      url = "path:/home/saber/projects/omarchy-nix";
    };

    agenix.url = "github:ryantm/agenix";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs-unstable,
      nixpkgs,
      nixos-hardware,
      home-manager,
      darwin,
      nix-homebrew,
      ...
    }@inputs:
    {
      darwinConfigurations = (
        import ./host/imbp/default.nix {
          inherit (nixpkgs) lib;
          inherit
            self
            inputs
            darwin
            nixpkgs
            nixpkgs-unstable
            home-manager
            nix-homebrew
            ;
        }
      );

      nixosConfigurations.saber = (
        import ./host/saber/default.nix {
          inherit (nixpkgs) lib;
          inherit
            self
            inputs
            nixpkgs
            nixpkgs-unstable
            nixos-hardware
            ;
        }
      );

      nixosConfigurations.xucxich = (
        import ./host/xucxich/default.nix {
          inherit (nixpkgs) lib;
          inherit
            self
            inputs
            nixpkgs
            nixpkgs-unstable
            ;
        }
      );

      nixosConfigurations.popcorn = (
        import ./host/popcorn/default.nix {
          inherit (nixpkgs) lib;
          inherit
            self
            inputs
            nixpkgs
            nixpkgs-unstable
            ;
        }
      );
    };
}
