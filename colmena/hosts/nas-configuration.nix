{ ... }:
{

  networking.firewall.enable = false;

  ## gluster server volumes
  # fileSystems."/srv/gluster/appdata" = {
  #   device = "/dev/disk/by-label/appdata";
  #   fsType = "btrfs";
  #   options = [ "noatime" ];
  # };
  # fileSystems."/srv/gluster/media" = {
  #   device = "/dev/disk/by-label/media";
  #   fsType = "btrfs";
  #   options = [ "noatime" ];
  # };

  preservation = {
    enable = true;

    preserveAt."/persist" = {
      directories = [
        "/etc/nixos"
        # "/var/lib/tailscale"
        # "/var/lib/glusterd"
        # {
        #   directory = "/var/lib/nixos";
        #   inInitrd = true;
        # }
      ];

      files = [
        "/etc/ssh/authorized_keys.d/operateur"
        { # PRevent Failed to start Save Transient machine-id to Disk
          file = "/etc/machine-id";
          inInitrd = true;
          how = "symlink";
        }
      ];

      # Preserve user files
      users.operateur = {
        directories = [ ".ssh" ];
        files = [ ".gitconfig" ".config/nushell/config.nu" ".config/nushell/zoxide.nu" ];
      };
      users.root = {
        home = "/root";
        directories = [];
        files = [ ".gitconfig" ];
      };
    };
  };
}
