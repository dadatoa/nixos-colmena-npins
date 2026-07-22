{ config, lib, pkgs, ... }:

{
  services.technitium-dns-server = {
    enable = true;
    # package = pkgs.unstable.technitium-dns-server;
  };

  services.jellyfin = {
    enable = true;
    user= "operateur";
    package = pkgs.unstable.jellyfin;
    cacheDir = "/var/cache/jellyfin";
  };
}
