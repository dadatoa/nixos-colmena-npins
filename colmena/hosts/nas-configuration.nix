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

  environment.systemPackages = [
    pkgs.colmena
  ];

  preservation = {
    preserveAt."/persist" = {
      files = [
        # "/etc/systemd/network/keys/proton.key"
      ];
      directories = [ "/data" ];
      # Preserve user files
      users.operateur = {
        directories = [ ".ssh" ".local/share/containers" ];
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
          Origins = lib.mkForce "http://127.0.0.1:9090 https://127.0.0.1:9090 http://10.10.10.209:9090 https://10.10.10.209:9090 http://nas.local:9090 https://nas.local:9090" ;
        };
      };
    };
    ## add udisk2 to enable disk visualisation in cockpit
    services.udisks2.enable = true;
    users.users.operateur.linger = true;
    systemd.services.linger-users.unitConfig.StartLimitBurst = 20;
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
          VPN_PORT_FORWARDING = "on";
          SERVER_COUNTRIES = "Singapore";
        };
        environmentFiles = [ /persist/keys/proton.key];
        ports = [ "8080:8080/tcp" "6881:6881/tcp" "6881:6881/udp" ];
        image = "qmcgaw/gluetun";
      };
      containers."qbittorrent" = {
        podman.user = "operateur";
        environment = {
          TZ = "Asia/Bangkok";
        };
        dependsOn = [ "gluetun" ];
        extraOptions = [ "--network=container:gluetun" "--userns=keep-id" ];
        volumes = [ "qbittorrent.etc:/qbittorrent/etc" "qbittorrent.var:/qbittorrent/var" "/data/media:/media"];
        image = "quay.io/11notes/qbittorrent:5.2.1";
      };
      containers."prowlarr" = {
        podman.user = "operateur";
        environment = {
          TZ = "Asia/Bangkok";
          PUID = "1000";
          PGID = "1000";
        };
        volumes = [ "prowlarr.etc:/config" ];
        ports = [ "9696:9696/tcp" ];
        image = "lscr.io/linuxserver/prowlarr:latest";
      };
      containers."radarr" = {
        podman.user = "operateur";
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Asia/Bangkok";
        };
        volumes = [ "radarr.etc:/config" "/data/media:/media"];
        ports = [ "7878:7878/tcp" ];
        image = "lscr.io/linuxserver/radarr:latest";
      };
      containers."sonarr" = {
        podman.user = "operateur";
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Asia/Bangkok";
        };
        volumes = [ "sonarr.etc:/config" "/data/media:/media"];
        ports = [ "8989:8989/tcp" ];
        image = "lscr.io/linuxserver/sonarr:latest";
      };
      containers."jellyfin" = {
        podman.user = "operateur";
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Asia/Bangkok";
        };
        ports = [ "8096:8096/tcp"];
        extraOptions = [ "--userns=keep-id" ];
        volumes = [ "jellyfin.etc:/config" "/data/media:/media"];
        image = "lscr.io/linuxserver/jellyfin:latest";
      };
    };
    ## mount media subvolume for container bittorrent
    fileSystems."/data/media" = {
      device = "/dev/disk/by-label/media";
      fsType = "btrfs";
      options = [ "subvol=media" "noatime" "compress=zstd:3" "space_cache=v2" "nossd" ];
  
    };
    systemd.services.podman-qbitorrent = {
      after = [ "data-media.mount" ];
      wants = [ "data-media.mount" ];
    };
}
