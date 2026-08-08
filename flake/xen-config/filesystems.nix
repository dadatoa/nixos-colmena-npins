
{ config, lib, pkgs, modulesPath, ... }:

{
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "size=25%" "mode=755" ]; # mode=755 so only root can write to those files
    };

  fileSystems."/boot" = {
    neededForBoot = true;
    device = "/dev/disk/by-uuid/A39E-73FE";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
    };

  fileSystems."/var" ={
    neededForBoot = true;
    device = "/dev/mapper/sys-dom0";
    fsType = "btrfs";
    options = [ "subvol=@var" "compress=zstd" "noatime" ];
    };

  fileSystems."/persist" = {
    neededForBoot = true;
    device = "/dev/mapper/sys-dom0";
    fsType = "btrfs";
    options = [ "subvol=@persist" "compress=zstd" "noatime"];
    };

  fileSystems."/nix" = {
    neededForBoot = true;
    device = "/dev/mapper/sys-dom0";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/a6a0f0a7-f380-496e-b341-65466510ffca"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

}
