{ ... }:
{
  imports = [
    ../../common/xen_domU.nix
  ];

  ## gluster server volumes
  fileSystems."/srv/gluster/appdata" = {
    device = "/dev/disk/by-label/appdata";
    fsType = "btrfs";
    options = [ "noatime" ];
  };
  fileSystems."/srv/gluster/media" = {
    device = "/dev/disk/by-label/media";
    fsType = "btrfs";
    options = [ "noatime" ];
  };

  preservation = {
    enable = true;

    preserveAt."/persist" = {
      directories = [
        "/etc/nixos"
        # "/var/lib/bluetooth"
        "/var/lib/tailscale"
        "/var/lib/glusterd"
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
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
        directories = [ ".ssh" ];
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
