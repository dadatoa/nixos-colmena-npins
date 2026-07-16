{ config, lib, pkgs, ... }:

{
  programs.mosh.enable = true;
  # start ssh-agent
  programs.ssh.startAgent = true;

  services.openssh.enable = true;

  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };

  # Enable mDNS autodiscovery
  services.avahi = {
    publish = {
      enable = true;
      userServices = true;
    };
    enable = true;
    openFirewall = true;
    nssmdns4 = true;
  };

}
