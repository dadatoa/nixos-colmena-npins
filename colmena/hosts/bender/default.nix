{ ... }:
{
  imports = [
    ../../common/xen_domU.nix
    ../../common/docker.nix
    ./services.nix
  ];

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
        # "/var/lib/bluetooth"
        "/var/lib/tailscale"
        "/var/lib/glusterd"
        {
          directory = "/var/lib/jellyfin";
          user = "operateur";
          group = "operateur";
        }
        {
          directory = "/var/cache/jellyfin";
          user = "operateur";
          group = "operateur";
        }
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
