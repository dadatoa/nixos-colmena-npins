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
      # allowUnfree = true;
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
  defaults = { pkgs, ... }: {
    imports = [ ./common/locale.nix ./common/users.nix ];
    environment.systemPackages = [ pkgs.git pkgs.vim ];
    services.openssh.enable = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
  };

  web01 = { ... }: {
    deployment = {
      targetHost = "web01.example.com";
      targetUser = "root";
      tags = [ "web" ];
    };
    imports = [ ./hosts/web01.nix ];
  };

  db01 = { ... }: {
    deployment = {
      targetHost = "db01.example.com";
      targetUser = "root";
      tags = [ "db" ];
    };
    imports = [ ./hosts/db01.nix ];
  };

  xen = { ... }: {
    deployment = {
      targetHost = "xen.example.com";
      targetUser = "root";
      tags = [ "hypervisor" ];
    };
    imports = [ ./hosts/xen.nix ];
  };
}
