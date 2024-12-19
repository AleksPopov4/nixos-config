{ lib ? import <nixpkgs/lib>, inputs, specialArgs, config, options, modulesPath }:
let
  createZfsConfig = {
    #devices,
    #redundancy ? 0,
    espSize ? "512M",
    swapSize ? "16G",
  }:

  {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          imageSize = "34G";
          device = "/dev/vda";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                size = "1M";
                type = "EF02"; # for grub MBR
              };
              ESP = {
                size = espSize;
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              # Allocate some fixed size for persist, say 10G.
              persist = {
                size = "100%-" + swapSize;
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/persist";
                };
              };
              swap = {
                size = swapSize;
                content = {
                  type = "swap";
                };
              };
            };
          };
        };
      };
    };
  };
in
createZfsConfig
