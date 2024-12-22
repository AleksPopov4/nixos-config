{ lib }:
{
  createZfsConfig = {
    espSize ? "512M",
    swapSize ? "16G",
  }:
  {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          imageSize = "50G";
          #device = "/dev/vda";
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
              root = {
                size = "16G";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
              persist = {
                size = "16G";
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
}
