{
  networking.hostName = "nixos-vm";
  
  networking.firewall.enable = false; 
  
## manage network with systemd
  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network.networks = {
    "30-lan" = {
      matchConfig.Name = "enX0";
      networkConfig.DHCP = "ipv4";
    };
  };
}
