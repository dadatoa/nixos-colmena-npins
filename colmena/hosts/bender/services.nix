{ config, lib, pkgs, ... }:

{
 services.technitium-dns-server.enable = true;
 services.jellyfin = {
   enable = true;
   dataDir = "/data/appdata/jellyfin";
   user= "operateur";
   package = pkgs.unstable.jellyfin;
 };
}
