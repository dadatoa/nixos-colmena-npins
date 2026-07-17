{ config, lib, pkgs, ... }:

{
 services.technitium-dns-server.enable = true;
 services.jellyfin = {
   enable = true;
   datadir = "/data/appdata/jellyfin";
   user= "operateur";
 };
}
