{ ... }:
{

  networking.firewall.enable = false;

  # gluster server volumes
  # fileSystems."/srv/gluster/appdata" = {
  #   device = "/dev/disk/by-label/appdata";
  #   fsType = "btrfs";
  #   options = [ "noatime" ];
  # };
  fileSystems."/srv/gluster/chill" = {
    device = "/dev/disk/by-label/media";
    fsType = "btrfs";
    options = [ "noatime" ];
  };
  # mount gluster volume
  fileSystems."/data/media" = {
    device = "nas.local:/media";
    fsType = "glusterfs";
  };
  systemd.network = {
    # 1. Define the WireGuard NetDev interface
    netdevs."50-wg-proton" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg-proton";
        MTUBytes = "1420";
      };
      wireguardConfig = {
        PrivateKeyFile = "/persist/keys/proton.key";
      };
      wireguardPeers = [
        {
        PublicKey = "WgRtf+TKPVKDfc/3B81bf+EfmPvwGYzucIyg8nCj800=";
        Endpoint = "103.216.223.50:51820";
        AllowedIPs = [ "0.0.0.0/0" ]; # Route all traffic through VPN
        PersistentKeepalive = 25;
        }
      ];
    };

    # 2. Configure network assignment and routing for the interface
    networks."50-wg-proton" = {
      matchConfig.Name = "wg-proton";
      address = [
        "10.2.0.2/32" # Replace with your ProtonVPN assigned IPv4 address
      ];
      networkConfig = {
        # Automatically assign routes for the allowedIPs
        DNS = [ "10.2.0.1" ]; # ProtonVPN's internal DNS server if applicable
      };
      linkConfig.RequiredForOnline = "no"; # Prevents boot hangs if VPN is slow to connect
    };
  };

  preservation = {
    preserveAt."/persist" = {
      files = [
        # "/etc/systemd/network/keys/proton.key"
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
