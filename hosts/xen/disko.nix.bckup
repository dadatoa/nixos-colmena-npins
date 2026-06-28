{
  
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/persist" = {
    neededForBoot = true; # sometimes needed too
    device = "/dev/nvme_vg/dom0";
    fsType = "btrfs";
    options = ["subvol=persist" "compress=zstd" "noatime"];
  };
  
  disko.devices = {
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=25%"
          "mode=755"
        ];
      };
    };
    
    disk.main = {
      # device = "/dev/nvme0n1";
      device = "/dev/disk/by-id/nvme-EDILOCA_EN600_Pro_512GB_AA240220910";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          esp = {
            name = "ESP";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              # mountOptions = [ "umask=0077" ];
            };
          };
          swap = {
            size = "4G";
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };
          # root 
          main = {
            name = "main";
            size = "100%";
            content = {
              type = "lvm_pv";
              # vg = "root_vg";
              vg = "nvme_vg";
            };
          };
        };
      };
    };
    lvm_vg = {
      # root_vg 
      nvme_vg = {
        type = "lvm_vg";
        lvs = {
          dom0 = {
            size = "20G";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/nix" = {
                  mountOptions = [ "subvol=nix" "noatime" ];
                  mountpoint = "/nix";
                };
                "/persistent" = {
                  mountOptions = [ "subvol=persistent" "noatime"];
                  mountpoint = "/persistent";
                };
              };
            };
          };
        };
      };
    };
  };
}
