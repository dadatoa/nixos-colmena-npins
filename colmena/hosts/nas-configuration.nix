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
    pkgs.unstable.jellyfin
    pkgs.unstable.jellyfin-web
    pkgs.unstable.jellyfin-ffmpeg
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
    # Create System service that ensures the rootless network exists for user 'operateur'
    # need to attach prowlarr and flaresolver to the samenetwork in order to make it work
    # i will put all -arr stack under th same network
    systemd.services.create-7seas-network = {
      description = "Create 7seas Podman network for operateur";
      wantedBy = [ "multi-user.target" ];
      before = [
        "podman-flaresolverr.service"
        "podman-prowlarr.service"
        "podman-radarr.service"
        "podman-sonaar.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        User = "operateur";
        RemainAfterExit = true;
        ExecStart = "${pkgs.podman}/bin/podman network exists 7seas || ${pkgs.podman}/bin/podman network create 7seas";
      };
    };
  
    virtualisation.oci-containers = {
      containers."gluetun" = {
        podman.user = "operateur";
        capabilities.NET_ADMIN = true;
        devices = [ "/dev/net/tun:/dev/net/tun" ];
        extraOptions = [ "--network=7seas" ];
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
        extraOptions = [ "--network=7seas" "--userns=keep-id" ];
        dependsOn = [ "flaresolverr" ];
        volumes = [ "prowlarr.etc:/config" ];
        ports = [ "9696:9696/tcp" ];
        image = "lscr.io/linuxserver/prowlarr:latest";
      };
      containers."radarr" = {
        podman.user = "operateur";
        extraOptions = [ "--network=7seas" "--userns=keep-id" ];
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
        extraOptions = [ "--network=7seas" "--userns=keep-id" ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Asia/Bangkok";
        };
        volumes = [ "sonarr.etc:/config" "/data/media:/media"];
        ports = [ "8989:8989/tcp" ];
        image = "lscr.io/linuxserver/sonarr:latest";
      };
      containers."flaresolverr" = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        podman.user = "operateur";
        autoStart = true;
        extraOptions = [
          "--network=7seas"
          "--name=flaresolverr"
          "--userns=keep-id"
        ];
        ports = [ "8191:8191" ];
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
  # services.jellyfin = {
  #     enable = true;
  #     openFirewall = true;
  #     package = pkgs.unstable.jellyfin;
  #   };
}
