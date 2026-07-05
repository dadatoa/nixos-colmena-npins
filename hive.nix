let
  sources = import ./npins;

  # Overlay that exposes the unstable channel as `pkgs.unstable.*` on every node.
  # It inherits the base system and config (allowUnfree, etc.) so unstable
  # packages evaluate consistently with the rest of the system.
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

    # For non-x86_64 nodes, override nixpkgs per node so the overlay is applied
    # with the correct system, e.g.:
    # nodeNixpkgs.arm01 = import sources.nixpkgs {
    #   system = "aarch64-linux";
    #   overlays = [ unstableOverlay ];
    # };
  };

  # Applied to every node.
  defaults = { pkgs, ... }:
  {
    deployment.buildOnTarget = true;

    boot.supportedFilesystems.btrfs = true;

    imports = [
      (sources.disko + "/module.nix")
      (sources.preservation + "/module.nix")
      ./common/locale.nix
      ./common/users.nix
    ];

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    nix.settings.auto-optimise-store = true;
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nix.channel.enable = false;

    environment.systemPackages = with pkgs; [
      btrfs-progs
      e2fsprogs # ext2,3,4 filesytem
      git
      iproute2
      pciutils
      usbutils
      vim
      wget
    ];

    programs.mosh.enable = true;
    # start ssh-agent
    programs.ssh.startAgent = true;

    services.openssh.enable = true;

    # enable Tailscale with config
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
  };

  xen = { ... }:
  {
    deployment = {
      targetHost = "100.107.28.98";
      targetUser = "operateur";
      tags = [ "dom0" ];
    };
    imports = [ ./hosts/xen ];
  };
  nas = { ... }:
  {
    deployment = {
      targetHost = "100.70.23.23";
      targetUser = "operateur";
      tags = [ "domu" ];
    };
    imports = [ ./hosts/nas ];
  };
  deckard = { ... }:
  {
    deployment = {
      # Allow local deployment with `colmena apply-local`
      allowLocalDeployment = true;
      targetHost = "100.127.50.22";
      targetUser = "operateur";
      tags = [ "domu" ];
    };
    imports = [ ./hosts/deckard ];
  };

  giles = { ... }:
  {
    deployment = {
      targetHost = "100.82.170.70";
      targetUser = "operateur";
      tags = [ "domu" ];
    };
    imports = [ ./hosts/giles ];
  };
}
