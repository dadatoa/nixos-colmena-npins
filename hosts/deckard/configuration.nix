{ config, pkgs, lib, ... }:
{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  system.stateVersion = "26.05";

  environment.systemPackages = with pkgs; [
  ];

  networking.hostName = "deckard";

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

  services.glusterfs.enable = true;
}
