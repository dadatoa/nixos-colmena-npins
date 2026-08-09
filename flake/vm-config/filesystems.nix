{
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "size=25%" "mode=755" ]; # mode=755 so only root can write to those files
    };

  fileSystems."/nix" = {
    neededForBoot = true;
    device = "/dev/xvda";
    fsType = "btrfs";
    options = ["subvol=nix" "compress=zstd" "noatime"];
  };
  fileSystems."/persist" = {
    neededForBoot = true;
    device = "/dev/xvda";
    fsType = "btrfs";
    options = ["subvol=persist" "compress=zstd" "noatime"];
  };
  fileSystems."/boot" = {
    neededForBoot = true;
    device = "/dev/xvda";
    fsType = "btrfs";
    options = ["subvol=boot" "noatime"];
  };
  fileSystems."/var" = {
    neededForBoot = true;
    device = "/dev/xvda";
    fsType = "btrfs";
    options = ["subvol=var" "noatime"];
  };
  # Persistent swap file on /persist subvolume.
  # The /persist directory must exist and contain a swapfile created with:
  #   mkswap -U clear /persist/swapfile
  #   chmod 600 /persist/swapfile
  swapDevices = [
    {
      device = "/persist/swapfile";
      size = 4 * 1024; # 4GB
    }
  ];
}

