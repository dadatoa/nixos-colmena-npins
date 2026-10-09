{ config, lib, pkgs, ... }:

{
  # start ssh-agent
  programs.ssh.startAgent = true;

  services.openssh.enable = true;
  services.openssh.extraConfig = ''
    StreamLocalBindUnlink yes
  '';

  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
    authKeyFile = "/persist/keys/ts_secret";
    authKeyParameters.ephemeral = false;
    authKeyParameters.preauthorized = true;
    extraUpFlags = [ "--advertise-tags=tag:prod" "--ssh" ];
  };

  # Deployments connect over Tailscale (see deployment.targetHost in hive.nix).
  # If a nixpkgs bump changes the sshd/tailscale/systemd-networkd unit files,
  # switch-to-configuration restarts them during activation, which drops the
  # colmena SSH session mid-deploy ("Connection ... closed by remote host",
  # exit 255). Keep these from restarting on switch.
  systemd.services."sshd".restartIfChanged = false;
  systemd.services."tailscaled".restartIfChanged = false;
  systemd.services."systemd-networkd".restartIfChanged = false;

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
