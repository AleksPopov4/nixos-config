{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, ... }@inputs: {
    nixosConfigurations.mymachine = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs.inputs = inputs;
      modules = [
        disko.nixosModules.disko
        ./configuration.nix

        ({ config, lib, pkgs, ... }: let
           diskoConfig = import ./disko-config.nix {
             lib = lib;
           };
           zfsConfig = diskoConfig.createZfsConfig {
             espSize = "512M";
             swapSize = "16G";
           };
         in {
           disko.devices = zfsConfig.disko.devices;
        })
      ];
    };
  };
}
