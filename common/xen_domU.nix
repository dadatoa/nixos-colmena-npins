{ config, pkgs, lib, ... }:
{
  imports = [
    # ../remote_access.nix
  ];
  # Common configuration for Xen DomU NixOS virtual machines.
  boot = {
    growPartition = true;
    kernelParams = ["console=ttyS0" "vga=0x317" "nomodeset"];
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
}
