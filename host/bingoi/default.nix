{
  lib,
  inputs,
  nixpkgs,
  ...
}:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit inputs; };
  modules = [
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    ./hardware-configuration.nix
    ./configuration.nix
    ./incus.nix
  ];
}
