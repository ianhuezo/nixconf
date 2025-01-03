{
  disko.devices = {
    disk = {
      nvme = {
        type = "disk";
        # You'll want to identify your exact NVMe device path
        # Common paths are /dev/nvme0n1 or similar
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            # Recreating your existing boot partition
            boot = {
              name = "boot";
              size = "512M";  # Standard size for EFI partition
              type = "EF00";  # EFI System Partition type
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                # Preserving your existing boot partition options
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            # Recreating your root partition
            root = {
              name = "root";
              size = "100%";  # Use remaining space
              content = {
                type = "filesystem";
                # Keeping ext4 as your filesystem since that's what you're currently using
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
