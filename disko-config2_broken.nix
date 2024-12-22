{ lib }:
{
  createZfsConfig = {
    devices ? [],
    espSize ? "512M",
    swapSize ? "16G",
  }:
  let
  # Convert the list of devices into a set of device configurations.
  # Each device gets a GPT with:
  # - An EFI partition of espSize
  # - A swap partition of swapSize
  # - A ZFS partition with the remaining space
  deviceAttrs = lib.genAttrs devices (d: {
    name = "main${toString d}";
    value = {
    type = "disk";
    content = {
      tableType = "gpt";
      partitions = [
        {
          size = espSize;
          type = "efi";
          flags = [ "boot" ];
        }
        {
          size = swapSize;
          type = "swap";
        }
        {
          # Remaining space for ZFS
          type = "zfs";
        }
      ];
    };
    };
  });
in
{
  disko = {
    devices = deviceAttrs;

    zfs = {
      pools = {
        rpool = {
          disks = devices;
          # A stripe (redundancy=0) uses `type = "stripe"` and includes all devices.
          vdevs = [
            {
              type = "stripe";
              devices = devices;
            }
          ];
        };
      };
    };
  };
};
}
