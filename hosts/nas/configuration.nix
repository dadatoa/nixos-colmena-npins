{ lib, pkgs, ... }:
{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  system.stateVersion = "26.05";

  environment.systemPackages = with pkgs; [ forgejo-runner];

  networking.hostName = "nas";

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
