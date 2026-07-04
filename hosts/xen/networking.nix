{ ... }:
{
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

      # VLAN 50 interface on the physical NIC
      "20-vlan50" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "enp2s0.50";
        };
        vlanConfig.Id = 50;
      };

      # Isolated bridge for VLAN 50 — dom0 has no IP on this bridge
      "20-xenbr50" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "xenbr50";
          Description = "xen isolated bridge for VLAN 50";
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
        vlan = [ "enp2s0.50" ];
      };

      # Enslave the VLAN 50 interface to the isolated bridge
      "35-vlan50" = {
        matchConfig.Name = "enp2s0.50";
        networkConfig.Bridge = "xenbr50";
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
    };
  };
}
