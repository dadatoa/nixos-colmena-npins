{ config, lib, pkgs, modulesPath, ... }:
{

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "26.05";

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
      # "vga=ask"
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
    grub2_pvgrub_image
    # grub2
    # python3 # add python for Xen guest management with ansible
    colmena
  ];


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


  networking.firewall.enable = false;

  ## manage network with systemd
  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network = {
    netdevs = {
      # declare virtual devices
      "20-xenbr0" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "xenbr0";
          Description = "xen default bridge";
        };
      };

      # VLAN 50 & 66 interface on the physical NIC
      "20-vlan50" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "enp2s0.50";
        };
        vlanConfig.Id = 50;
      };

      "20-vlan66" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "enp2s0.66";
        };
        vlanConfig.Id = 66;
      };

      # Isolated bridge for VLAN 50 & 66 — dom0 has no IP on this bridge
      "20-xenbr50" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "xenbr50";
          Description = "xen isolated bridge for VLAN 50";
        };
      };
      "20-xenbr66" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "xenbr66";
          Description = "xen isolated bridge for VLAN 66";
        };
      };
    };

    networks = {
      # network interfaces configurations
      "30-lan" = {
        enable = true;
        matchConfig.Name = "enp2s0";
        networkConfig.Bridge = "xenbr0";
        # Declare the VLAN sub-interface so systemd-networkd creates it
        vlan = [ "enp2s0.50" "enp2s0.66"];
      };

      # Enslave the VLAN 50 interface to the isolated bridge
      "35-vlan50" = {
        matchConfig.Name = "enp2s0.50";
        networkConfig.Bridge = "xenbr50";
      };

      # Enslave the VLAN 66 interface to the isolated bridge
      "35-vlan66" = {
        matchConfig.Name = "enp2s0.66";
        networkConfig.Bridge = "xenbr66";
      };

      "40-xenbr0" = {
        matchConfig.Name = "xenbr0";
        networkConfig.DHCP = "ipv4";
      };

      # No IP on dom0 for this bridge — only domU guests use VLAN 50
      "40-xenbr50" = {
        matchConfig.Name = "xenbr50";
        networkConfig = {
          DHCP = "no";
          LinkLocalAddressing = "no";
        };
      };
      # No IP on dom0 for this bridge — only domU guests use VLAN 66
      "40-xenbr66" = {
        matchConfig.Name = "xenbr66";
        networkConfig = {
          DHCP = "no";
          LinkLocalAddressing = "no";
        };
      };
    };
  };
  preservation = {

    preserveAt."/persist" = {
      files = [
        "/etc/ssh/authorized_keys.d/operateur"
        "/etc/xen/auto/nas.cfg"
        "/etc/xen/auto/alp-dns1.cfg"
      ];
      users.operateur = {
        directories = [ ".ssh" ".config" "xl-configs" ];
        files = [ ".gitconfig" ];
      };

    };
  };
  services.cockpit = {
    enable = true;
    port = 9090;
    plugins = [
      pkgs.cockpit-files
    ];
    # openFirewall = true; # Please see the comments section
    settings = {
      WebService = {
        # AllowUnencrypted = true; # 2026-08-04: Not needed anymore?
        Origins = lib.mkForce "http://127.0.0.1:9090 https://100.113.83.131";
      };
    };
  };

}
