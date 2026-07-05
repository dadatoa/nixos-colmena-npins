{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  boot.supportedFilesystems.btrfs = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.settings.auto-optimise-store = true;

  environment.systemPackages = with pkgs; [
    btrfs-progs
    e2fsprogs # ext2,3,4 filesytem
    git
    mosh # ssh kind of
    parted
    pciutils
    usbutils
    vim
    wget
    python3
  ];

}
