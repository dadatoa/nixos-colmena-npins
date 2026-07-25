{ config, lib, pkgs, ... }:
{
  imports = [
    # ../../common/docker.nix
  ];

  services.technitium-dns-server = {
    enable = true;
    package = pkgs.unstable.technitium-dns-server;
    openFirewall = true;
  };
}
