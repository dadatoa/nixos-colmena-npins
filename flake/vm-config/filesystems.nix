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

  swapDevices = [{ 
    device = "/swap/swapfile"; 
    size = 4*1024; # Creates an 4GB swap file 
  }];
}

