{ config, pkgs, ... }:

{
  networking.useNetworkd = true;
  networking.useDHCP = false; # systemd-networkd handles things natively

  # Ensure resolved is enabled for DNS handling
  services.resolved.enable = true;

  systemd.network = {
    enable = true;

    # 1. Define the WireGuard NetDev interface
    netdevs = {
      "50-wg-proton" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg-proton";
          MTUBytes = "1420";
        };
        wireguardConfig = {
          PrivateKeyFile = "/etc/systemd/network/keys/proton.key";
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
    };

    # 2. Configure network assignment and routing for the interface
    networks = {
      "50-wg-proton" = {
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
  };
}
