{ pkgs, ... }:
{
  networking.hostName = "xen";

  # Minimal bootable layout so the configuration evaluates/builds.
  # Replace these with the real values from the target's hardware-configuration.nix.
  #
  # The Xen dom0 module requires systemd-boot (or Lanzaboote/Limine) and a
  # systemd-based initrd, so this host boots via UEFI rather than GRUB.
  boot.kernelParams = [
    ### xen special boot kernel param
    ### hide pci device wifi from dom0 to be abble to pass it on anther damain
    # "xen-pciback.hide=(03:00.0)"
    "intel_iommu=on"
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.consoleMode = "0";

  boot.loader.efi.canTouchEfiVariables = true;

  ## use latest kernel available
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # to disable "A start job is running for /dev/tpmrm0" timeout
  systemd.tpm2.enable = false;
  # if the previous one is not enough:
  boot.initrd.systemd.tpm2.enable = false;

  boot.initrd.systemd.enable = true;
  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];

  # Run as a Xen Project type-1 hypervisor; NixOS becomes the privileged dom0.
  virtualisation.xen = {
    enable = true;
    boot.builderVerbosity = "info";
    ## Adds a handy report that lets you know which Xen boot entries were created.
    boot.params = [
      "vga=ask"
      "dom0=pvh"
    ];
    # Uses the PVH virtualisation mode for the Domain 0, instead of PV.
    # Cap dom0's own resources so guest domains have headroom (adjust per host).
    dom0Resources = {
      memory = 2048; # MiB pinned to dom0
      maxVCPUs = 2;
    };
  };

  ## aditionnal usefull packages for xen
  environment.systemPackages = with pkgs; [
    qemu_xen
    grub2_xen
    grub2_xen_pvh
    grub2_pvhgrub_image
    grub2
    python3 # add python for Xen guest management with ansible
  ];

  networking.firewall.enable = false;
  ## manage network with systemd
  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network = {
    netdevs = {
      # # declare virtual devices
      "20-xenbr0" = {
        # bridge
        netdevConfig = {
          Kind = "bridge";
          Name = "xenbr0";
          Description = "xen default bridge";
        };
      };
    };
    networks = {
      # # network interfaces configurations
      "30-lan" = {
        enable = true;
        matchConfig.Name = "enp2s0";
        networkConfig.DHCP = "ipv4";
        networkConfig.Bridge = "xenbr0";
      };

      "40-xenbr0" = {
        matchConfig.Name = "xenbr0";
        networkConfig.DHCP = "ipv4";
      };
    };
  };
  system.stateVersion = "26.05";
}
