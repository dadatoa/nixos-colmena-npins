{ config, pkgs, lib, ... }:
{
  # Common configuration for Xen DomU NixOS virtual machines.
  boot = {
    growPartition = false; # to avoid Failed to start growpart.service with impermanence
    kernelParams = [ "console=ttyS0" "vga=0x317" "nomodeset" ];
    loader.grub.enable = true;
    initrd.systemd.enable = true;
  };
  # Grub loader to allow pvh grub usage
  boot.loader.grub.device = "nodev";

  boot.initrd.kernelModules = [
    "xen-blkfront"
    "xen-tpmfront"
    "xen-kbdfront"
    "xen-fbfront"
    "xen-netfront"
    "xen-pcifront"
    "xen-scsifront"
  ];

  # Send syslog messages to the Xen console.
  services.syslogd.tty = "hvc0";

  # Don't run ntpd, since we should get the correct time from Dom0.
  services.timesyncd.enable = false;

  # Automatically log in at the virtual consoles.
  services.getty.autologinUser = "operateur";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  system.stateVersion = "26.05";

  # environment.systemPackages = with pkgs; [ forgejo-runner ];


  # Manage network with systemd
  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network.networks = {
    "30-lan" = {
      matchConfig.Name = "enX0";
      networkConfig.DHCP = "ipv4";
    };
  };

  services.glusterfs.enable = true;

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "size=25%"
      "mode=755"
    ]; # mode=755 so only root can write to those files
  };

  fileSystems."/nix" = {
    neededForBoot = true;
    device = "/dev/xvda";
    fsType = "btrfs";
    options = [
      "subvol=nix"
      "compress=zstd"
      "noatime"
    ];
  };
  fileSystems."/persist" = {
    neededForBoot = true;
    device = "/dev/xvda";
    fsType = "btrfs";
    options = [
      "subvol=persist"
      "compress=zstd"
      "noatime"
    ];
  };
  fileSystems."/boot" = {
    neededForBoot = true;
    device = "/dev/xvda";
    fsType = "btrfs";
    options = [
      "subvol=boot"
      "noatime"
    ];
  };
  fileSystems."/var" = {
    neededForBoot = true;
    device = "/dev/xvda";
    fsType = "btrfs";
    options = [
      "subvol=varlib"
      "noatime"
    ];
  };


  swapDevices = [
    {
      device = "/persist/swapfile";
      size = 4 * 1024; # Creates an 4GB swap file
    }
  ];
}
