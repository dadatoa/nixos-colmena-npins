{ ... }:
{
  imports = [
    ../../common/xen_domU.nix
    ../../common/docker.nix
    ./networking.nix
    ./services.nix
  ];

  fileSystems."/data" = {
    neededForBoot = true;
    device = "/dev/xvda";
    fsType = "btrfs";
    options = [
      "subvol=data"
      "noatime"
    ];
  };
  ## Gluster mounts
  fileSystems."/data/media" = {
    device = "100.70.23.23:gv_media";
    fsType = "glusterfs";
  };
  fileSystems."/data/appdata" = {
    device = "100.70.23.23:gv_appdata";
    fsType = "glusterfs";
  };

  preservation = {
    enable = true;

    preserveAt."/persist" = {
      directories = [
        "/etc/nixos"
      ];

      files = [
        "/etc/ssh/authorized_keys.d/operateur"
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];

      # Preserve user files
      users.operateur = {
        directories = [ ".ssh" ".config" ];
        files = [ ".gitconfig" ];
      };
      users.root = {
        home = "/root";
        directories = [];
        files = [ ".gitconfig" ];
      };
    };
  };
}
