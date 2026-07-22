{ ... }:
{
  systemd.network.networks = {
    "30-lan66" = {
      matchConfig.Name = "enX1";
      networkConfig.DHCP = "ipv4";
    };
  };
}
