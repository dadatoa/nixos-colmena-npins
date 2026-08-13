let sources = import ../npins;

  # Overlay that exposes the unstable channel as `pkgs.unstable.*` on every node.# It inherits the base system and config (allowUnfree, etc.) so unstable packages evaluate consistently with the rest of the system.
  unstableOverlay = final: prev: {
    unstable = import sources.unstable {
      inherit (prev) system;
      config = prev.config;
    };
  };

  pkgs = import sources.nixpkgs {
    config = {
      allowUnfree = true;
    };
    overlays = [ unstableOverlay ];
  };
in
{
  meta = {
    # Pin colmena's nixpkgs to the stable channel from npins.
    nixpkgs = pkgs;

    # Make the pinned sources available to every node module.
    specialArgs = { inherit sources; };
  };

  # Applied to every node.
  defaults = { pkgs, ... }:
  {
    deployment.buildOnTarget = true;
    deployment.allowLocalDeployment = true; # allow all hosts to deploy locally

    # Secrets fetched directly from OpenBao at deploy time by running a local
    # `bao` command as the colmena-app AppRole, then uploaded to
    # /run/keys/<name> on each target. Requires a valid BAO_ADDR/BAO_TOKEN
    # session on the machine running `colmena apply`.
    deployment.keys = {
      root_password_hash = {
        keyCommand = [ "bao" "kv" "get" "-field=root_password_hash" "secrets/projects/colmena" ];
        destDir = "/persist/keys";
      };
      operateur_password_hash = {
        keyCommand = [ "bao" "kv" "get" "-field=operateur_password_hash" "secrets/projects/colmena" ];
        destDir = "/persist/keys";
      };
      ts_secret = {
        keyCommand = [ "bao" "kv" "get" "-field=ts_secret" "secrets/projects/colmena" ];
        destDir = "/persist/keys";
      };
      proton_private_key = {
        keyCommand = [ "bao" "kv" "get" "-field=proton_private_key" "secrets/projects/colmena" ];
        destDir = "/persist/keys";
      };
      approle_id = {
        keyCommand = [ "bao" "kv" "get" "-field=approle-id" "secrets/projects/colmena" ];
        destDir = "/persist/keys";
      };
      approle_secret = {
        keyCommand = [ "bao" "kv" "get" "-field=approle-secret" "secrets/projects/colmena" ];
        destDir = "/persist/keys";
      };
    };

    boot.supportedFilesystems.btrfs = true;

    imports = [
      (sources.disko + "/module.nix")
      (sources.preservation + "/module.nix")
      ./common/locale.nix
      ./common/users.nix
      ./common/preservation.nix
    ];

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nix.channel.enable = false;

    environment.systemPackages = with pkgs; [
      btrfs-progs
      e2fsprogs # ext2,3,4 filesytem
      git
      gnupg
      iproute2
      pass
      pciutils
      usbutils
      vim
      wget
    ];
  };

  xen = { ... }:
  {
    networking.hostName = "xen";
    deployment = {
      targetHost = "100.85.206.102";
      targetUser = "operateur";
      tags = [ "dom0" ];
    };
    imports = [
      ./hosts/xen-configuration.nix
      ./common/remote.nix
    ];
  };
  nas = { ... }:
  {
    networking.hostName = "nas";
    deployment = {
      targetHost = "10.10.10.209";
      targetUser = "operateur";
      tags = [ "domu" ];
    };
    imports = [
      ./hosts/nas-configuration.nix
      ./common/remote.nix
      ./common/xen_domU.nix
    ];
  };
}
