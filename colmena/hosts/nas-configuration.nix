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
    preserveAt."/persist" = {
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
