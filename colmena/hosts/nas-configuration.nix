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
  # mount gluster volume - loopback mount, must wait for glusterd + network
  # manual `mount /data/media` works because glusterd is already running; at boot it failed
  # with `data-media.mount: Failed with result 'exit-code'` (18:52:04) -> use automount + _netdev
  fileSystems."/data/media" = {
    device = "127.0.0.1:/media";
    fsType = "glusterfs";
    options = [
      "_netdev"
      "nofail"
      "x-systemd.automount"
      "noauto"
      "x-systemd.device-timeout=60"
      "x-systemd.mount-timeout=60"
      "x-systemd.after=network-online.target"
      "x-systemd.after=glusterd.service"
    ];
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
          Origins = lib.mkForce "http://127.0.0.1:9090 https://127.0.0.1:9090 http://10.10.10.209:9090 https://10.10.10.209:9090 https://nas.blue-edmontosaurus.ts.net";
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
      containers."qbitorrent" = {
        podman.user = "operateur";
        environment = {
          TZ = "Asia/Bangkok";
        };
        dependsOn = [ "gluetun" ];
        extraOptions = [ "--network=container:gluetun" ];
        volumes = [ "qbittorrent.etc:/qbittorrent/etc" "qbittorrent.var:/qbittorrent/var" "/data/media:/media"];
        image = "quay.io/11notes/qbittorrent:5.2.1";
      };
    };
      # qbitorrent bind-mount /data/media: doit attendre l'automount glusterfs
      # nofail sur le mount => le 1er échec (glusterd pas encore prêt, 22:25:01) ne bloque pas le boot,
      # l'automount réessaie à 22:25:02 et réussit
      systemd.services.podman-qbitorrent = {
        after = [ "data-media.automount" "network-online.target" "glusterd.service" ];
        wants = [ "data-media.automount" ];
      };
}
