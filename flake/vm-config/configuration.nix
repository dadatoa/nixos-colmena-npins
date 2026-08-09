{ ... }:
{
  imports = [
    ../common
  ];
  # Common configuration for Xen DomU NixOS virtual machines.
  boot = {
    growPartition = false;
    kernelParams = [
      "console=hvc0"
      "nomodeset"
    ];
    loader.grub.enable = true;
    initrd.systemd.enable = true;
    # GRUB must not wait forever at the menu in a headless domU.
    loader.timeout = 5;
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
