{ config, lib, pkgs, ... }:

{
  services.technitium-dns-server = {
    enable = true;
    package = pkgs.unstable.technitium-dns-server;
    openFirewall = true;
  };

  services.jellyfin = {
    enable = true;
    user= "operateur";
    package = pkgs.unstable.jellyfin;
    cacheDir = "/var/cache/jellyfin";
    openFirewall = true;
  };
  environment.systemPackages = [ pkgs.unstable.jellyfin ];
}
