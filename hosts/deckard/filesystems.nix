{
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "size=25%" "mode=755" ]; # mode=755 so only root can write to those files
    };

  fileSystems."/nix" = {
    neededForBoot = true;
    device = "/dev/disk/by-uuid/4176eb8b-ab69-4313-bed8-dea05679a316";
    fsType = "btrfs";
    options = ["subvol=nix" "compress=zstd" "noatime"];
  };
  fileSystems."/persist" = {
    neededForBoot = true;
    device = "/dev/disk/by-uuid/4176eb8b-ab69-4313-bed8-dea05679a316";
    fsType = "btrfs";
    options = ["subvol=persist" "compress=zstd" "noatime"];
  };
  fileSystems."/boot" = {
    neededForBoot = true;
    device = "/dev/disk/by-uuid/4176eb8b-ab69-4313-bed8-dea05679a316";
    fsType = "btrfs";
    options = ["subvol=boot" "noatime"];
  };

  swapDevices = [{
    device = "/swap/swapfile";
    size = 4*1024; # Creates an 4GB swap file
  }];
}
