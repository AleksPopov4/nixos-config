{ lib ? import <nixpkgs/lib> } :
let
  makeMasterConfig = {
    devices,
    espSize ? "512M",
    swapSize ? "",
  }:
  let
  partitions = {
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
    zfs = {
      size = "100%";
      content = {
        type = "zfs";
        pool = "zroot";
      };
    };
  };
  maybeSwap = if swapSize == "" then {} else {
    swap = {
      size = swapSize;
      content = {
        type = "swap";
      };
    };
  };
  in {
    type = "disk";
    device = devices;
    content = {
      type = "gpt";
      partitions = partitions // maybeSwap;
    };
  };

  makeSlaveConfig = device: {
    type = "disk";
    device = device;
    content = {
      type = "gpt";
      partitions = {
        zfs = {
          size = "100%";
          content = {
            type = "zfs";
            pool = "zroot";
          };
        };
      };
    };
  };
  
  makeZpoolConfig = { members, mode }: {
    zroot = {
        type = "zpool";
        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                mode = mode;
                members = members;
              }
            ];
          };
        };
      };
    };

  extractMode = { devices, redundancy } :
    let 
      deviceCount = lib.length devices;

      zpoolMode = if redundancy == 0 then
          ""
        else if deviceCount < redundancy + 1 then
          (throw "Error: Not enough devices for redundancy=${toString redundancy}, need at least ${toString (redundancy+1)} devices.")
        else if deviceCount == redundancy + 1 then
          "mirror"
        else if redundancy == 1 then
          "raidz1"
        else if redundancy == 2 then
          "raidz2"
        else if redundancy == 3 then
          "raidz3"
        else
          (throw "Error: Redundancy > 3 not supported.");
    in zpoolMode;

  extractName = device:
    lib.lists.last (lib.strings.splitString "/" device);

  extractNames = members: 
    lib.lists.filter (e: e != "") (lib.strings.splitString "/" members);

  makeMaster = args:
    let
      name = extractName args.device;
      value = (makeMasterConfig args);
    in { name = name; value = value; };    

  makeSlave = device:
    let
      name = extractName device;
      value = makeSlaveConfig device;
    in { name = name; value = value; };

  makeMembers = args:
    let
      name = "zroot";
      value = (makeZpoolConfig args);
    in { name = name; value = value; };

  createZfsConfig = {
    devices ? ["/dev/sda" "/dev/sdb" "/dev/sdc"],
    redundancy ? 0,
    espSize ? "512M",
    swapSize ? "16G",
  }: {
    disko = {
      devices = {
        # TODO: FIX!
        disk = lib.listToAttrs (
          [ (makeMaster {
            devices = (builtins.head devices);
            espSize = espSize;
            swapSize = swapSize;
          }) ]
          ++
          (map makeSlave (builtins.tail devices))
        );
        zpool = lib.listToAttrs(
          [ (makeZpoolConfig {
            members = extractNames devices;
            mode = extractMode devices redundancy;
          }) ]
        );
      };
    };
  };
in {
  createZfsConfig = createZfsConfig;
}