{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ];
  programs.mosh.enable = true;
  # start ssh-agent
  programs.ssh.startAgent = true;
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # enable Tailscale with config
  services.tailscale = {
    enable = true;
  };
  
  ## enable mdns autodiscovery
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
