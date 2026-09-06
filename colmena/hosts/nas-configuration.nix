{ pkgs, lib, ... }:
{
  networking.firewall.enable = false;

  # gluster server volumes
  # fileSystems."/srv/gluster/appdata" = {
  #   device = "/dev/disk/by-label/appdata";
  #   fsType = "btrfs";
  #   options = [ "noatime" ];
  # };
  fileSystems."/srv/gluster/chill" = {
    device = "/dev/disk/by-label/media";
    fsType = "btrfs";
    options = [ "noatime" ];
  };
  # mount gluster volume
  fileSystems."/data/media" = {
    device = "nas.local:/media";
    fsType = "glusterfs";
  };

  services.jellyfin = {
    enable = true;
    package = pkgs.unstable.jellyfin;
  };

  environment.systemPackages = [
    pkgs.unstable.jellyfin-web
    pkgs.unstable.jellyfin-ffmpeg
    pkgs.colmena
  ];

  preservation = {
    preserveAt."/persist" = {
      files = [
        # "/etc/systemd/network/keys/proton.key"
      ];
      # Preserve user files
      users.operateur = {
        directories = [ ".ssh" ];
        files = [ ".gitconfig" ".config/nushell/config.nu" ".config/nushell/zoxide.nu" ];
      };
      users.root = {
        home = "/root";
        directories = [];
        files = [ ".gitconfig" ];
      };
    };
  };

    services.cockpit = {
      enable = true;
      port = 9090;
      plugins = [
        pkgs.cockpit-files
        pkgs.cockpit-podman
      ];
      # openFirewall = true; # Please see the comments section
      settings = {
        WebService = {
          # AllowUnencrypted = true; # 2026-08-04: Not needed anymore?
          Origins = lib.mkForce "http://127.0.0.1:9090 https://127.0.0.1:9090 http://10.10.10.209:9090 https://10.10.10.209:9090";
        };
      };
    };
    ## add udisk2 to enable disk visualisation in cockpit
    services.udisks2.enable = true;
    virtualisation.containers.enable = true;
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";
    virtualisation.oci-containers = {
      containers."gluetun" = {
        podman.user = "operateur";
        capabilities.NET_ADMIN = true;
        devices = [ "/dev/net/tun:/dev/net/tun" ];
        environment = {
          VPN_SERVICE_PROVIDER ="protonvpn";
          VPN_TYPE = "wireguard";
          SERVER_COUNTRIES = "Singapore";
        };
        environmentFiles = [ /persist/keys/proton.key];
        image = "qmcgaw/gluetun";
      };
    };
}
