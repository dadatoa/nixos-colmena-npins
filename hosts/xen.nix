{ ... }:
{
  networking.hostName = "xen";

  # Minimal bootable layout so the configuration evaluates/builds.
  # Replace these with the real values from the target's hardware-configuration.nix.
  #
  # The Xen dom0 module requires systemd-boot (or Lanzaboote/Limine) and a
  # systemd-based initrd, so this host boots via UEFI rather than GRUB.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  # Run as a Xen Project type-1 hypervisor; NixOS becomes the privileged dom0.
  virtualisation.xen.enable = true;

  # Cap dom0's own resources so guest domains have headroom (adjust per host).
  virtualisation.xen.dom0Resources = {
    memory = 2048;    # MiB pinned to dom0
    maxVCPUs = 2;
  };

  # Bridge for guest networking; attach the real uplink on the target host, e.g.
  #   networking.bridges.xenbr0.interfaces = [ "eno1" ];
  networking.bridges.xenbr0.interfaces = [ ];
  networking.interfaces.xenbr0.useDHCP = true;

  system.stateVersion = "26.05";
}
