{ lib ? import <nixpkgs/lib> }:
let
  createZfsConfig = {
    devices,
    redundancy ? 0,
    espSize ? "512M",
    swapSize ? "16G",
  }:

  let
    deviceCount = lib.length devices;

    # Determine the vdev type based on redundancy and deviceCount
    #
    # Rules:
    # redundancy = 0: always stripe
    #
    # redundancy >= 1:
    #   - If deviceCount < redundancy + 1: error (not enough devices for mirror)
    #   - If deviceCount = redundancy + 1: mirror (N-way mirror)
    #   - If deviceCount > redundancy + 1: RAID-Z (Z1 if redundancy=1, Z2 if redundancy=2, Z3 if redundancy=3)
    #
    # We'll represent vdevType as a string for clarity:
    # "stripe", "mirror", "raidz1", "raidz2", "raidz3"
    vdevType = if redundancy == 0 then
      "stripe"
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

    # Partition scheme rules from examples:
    #
    # For redundancy=0 (stripe):
    # - If deviceCount=1: single disk with ESP, ZFS, SWAP
    # - If deviceCount>1: first disk has ESP,ZFS,SWAP; all others have only ZFS
    #
    # For redundancy>=1 (mirror or raidz):
    # All disks have ESP,ZFS,SWAP
    #
    # Partitions:
    # On a disk with ESP,ZFS,SWAP:
    #   1) EF02 partition: size 1M at start (only if explicitly shown in examples? 
    #      The examples show a EF02 partition for GRUB MBR: We'll follow examples literally.
    #   2) EF00 partition: size espSize after EF02
    #   3) ZFS partition: after ESP up to -swapSize
    #   4) SWAP partition: last partition with size swapSize
    #
    # On a disk with only ZFS:
    #   ZFS partition uses entire disk (no ESP or SWAP)
    #
    # Note: The examples for redundancy≥1 show that all disks have the EF00 and SWAP as well. 
    #       They also have a EF02 partition at the start (1M) in the examples.
    #
    # We will always create the EF02 partition for consistency, as per provided examples.

    # Function to create partitions for a disk with ESP,ZFS,SWAP
    makeFullPartitions = {
      namePrefix
    }:
    {
      boot = {
        size = "1M";
        type = "EF02"; # GRUB BIOS Boot partition
      };
      ESP = {
        size = espSize;
        type = "EF00";
        content = {
          type = "filesystem";
          format = "vfat";
          # mountpoint might be handled by caller config; not strictly required here.
        };
      };
      zfs = {
        # ZFS from after ESP to -swapSize
        # Disko: Use relative sizes. We use size = "-swapSize" to leave space at end.
        # The start is automatically after ESP partition.
        size = "100%-" + swapSize;
        content = {
          type = "filesystem";
          format = "zfs";
        };
      };
      swap = {
        size = swapSize;
        content = {
          type = "swap";
        };
      };
    };

    # Function to create partitions for a disk with only ZFS
    makeZfsOnlyPartitions = {
      namePrefix
    }:
    {
      zfs = {
        size = "100%";
        content = {
          type = "filesystem";
          format = "zfs";
        };
      };
    };

    # Decide partition scheme per device index
    partitionsForDevice = lib.genList (i: if redundancy == 0 && deviceCount > 1 && i != 0
      then makeZfsOnlyPartitions {}
      else makeFullPartitions {}
    ) deviceCount;

    # Create a disko.devices set from our devices array
    # We'll name each device "mainX" for X in [0..deviceCount-1]
    deviceMap = lib.listToAttrs (lib.zipWith (d: p: {
      name = "main${toString d}";
      value = {
        type = "disk";
        device = devices.d;
        content = {
          type = "gpt";
          partitions = p;
        };
      };
    }) (lib.range 0 (deviceCount - 1)) partitionsForDevice);

    # Determine how to combine these partitions into a vdev
    # For stripe: zfs vdev = [ all zfs partitions in a stripe ]
    # For mirror: zfs vdev = [ all zfs partitions in a mirror ]
    # For raidzN: zfs vdev = [ all zfs partitions in a raidzN ]
    #
    # The exact format of Disko ZFS configuration may vary, but typically you define the devices and let Disko handle them.
    # We'll assume Disko just sets up partitions and the caller or a further module sets up the ZFS pool.
    #
    # If Disko supports specifying the top-level ZFS layout, you might produce a `disko.zfs` attribute. 
    # But the instructions only mentioned returning a configuration for partitioning.
    #
    # We'll just return the disk configuration here. The ZFS top-level config might be done elsewhere.

  in {
    disko.devices = deviceMap;
    # If needed, we could add hints about ZFS vdev structure here, but the prompt only asks for partitioning.
    # The caller can interpret vdevType and deviceCount to set up a zpool outside this function.
  };

in
{
  inherit createZfsConfig;
}
