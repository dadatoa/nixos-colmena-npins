{ config, lib, pkgs, ... }:

{
 services.technitium-dns-server.enable = true;
 services.jellyfin = {
   enable = true;
   user= "operateur";
   package = pkgs.unstable.jellyfin;
   cacheDir = "/var/cache/jellyfin";
 };
}
