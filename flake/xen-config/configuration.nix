{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../common
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  ###
  ### Xen project boot options
  ###
  boot.initrd.systemd.enable = true;
  ## for booting xen
  boot.initrd.kernelModules = [
    "dm-snapshot"
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];
  ############################
  ############################
  ############################

  virtualisation.xen = {
    enable = true;
    boot.builderVerbosity = "info";
    ## Adds a handy report that lets you know which Xen boot entries were created.

    boot.params = [
      "vga=ask"
      "dom0=pvh" # Uses the PVH virtualisation mode for the Domain 0, instead of PV.
    ];
    dom0Resources = {
      memory = 1024; # Only allocates 1GiB of memory to the Domain 0, with the rest of the system memory being freely available to other domains.
      maxVCPUs = 2; # Allows the Domain 0 to use, at most, two CPU cores.
    };
  };

  ## aditionnal packages
  environment.systemPackages = with pkgs; [
    qemu_xen
    grub2_xen
    grub2_xen_pvh
    grub2_pvhgrub_image
    grub2
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp3s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # DO NOT TOUCH
  system.stateVersion = "26.05";
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

  # boot.loader.systemd-boot.netbootxyz.enable = true;

  networking.hostName = "xen";

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
}
