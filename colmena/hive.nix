let sources = import ../npins;

  # The nixos-unstable snapshot currently pinned in npins/sources.json ships
  # opencode 2.2.5 with the pre-fix Linux output hash for its node_modules
  # fixed-output derivation, so deploying xen fails with a "hash mismatch".
  # Upstream fixed this in <https://github.com/NixOS/nixpkgs/pull/582675>
  # (c399e1b7). This only rewrites the hash of the exact broken derivation, so
  # it becomes a no-op once the pin advances past that commit.
  opencodeNodeModulesHashFix = final: prev: {
    opencode = prev.opencode.overrideAttrs (old: {
      node_modules =
        if old.version == "2.2.5" then
          old.node_modules.overrideAttrs (_: {
            outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
          })
        else
          old.node_modules;
    });
  };

  # Overlay that exposes the unstable channel as `pkgs.unstable.*` on every node.# It inherits the base system and config (allowUnfree, etc.) so unstable packages evaluate consistently with the rest of the system.
  unstableOverlay = final: prev: {
    unstable = import sources.unstable {
      inherit (prev) system;
      config = prev.config;
      overlays = [ opencodeNodeModulesHashFix ];
    };
  };

  # qemu-xen patched so that Intel IGD passthrough works from a dom0 running a
  # recent kernel (see patches/qemu-xen/README.md):
  #  - the sysfs "rom" attribute is a kstrtobool(), a raw 0x01 byte is refused
  #  - the VGA ROM BAR is registered twice for IGD passthrough because the host
  #    exposes the iGPU VBIOS as a shadow ROM (assert(!r->size) in
  #    pci_register_bar)
  qemuXenIgdOverlay = final: prev: {
    qemu_xen = prev.qemu_xen.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ../patches/qemu-xen/0001-xen-pt-write-rom-enable-as-text.patch
        ../patches/qemu-xen/0002-xen-pt-skip-rom-bar-for-igd.patch
      ];
    });
  };

  pkgs = import sources.nixpkgs {
    config = {
      allowUnfree = true;
    };
    overlays = [ unstableOverlay qemuXenIgdOverlay opencodeNodeModulesHashFix ];
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
        user = "operateur";
        group = "users";
      };
      ts_secret = {
        keyCommand = [ "bao" "kv" "get" "-field=ts_secret" "secrets/projects/colmena" ];
        destDir = "/persist/keys";
      };
      "proton.key" = {
        keyCommand = [ "bao" "kv" "get" "-field=proton_private_key" "secrets/projects/colmena" ];
        destDir = "/persist/keys";
        user = "operateur";
        group = "users";
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
      nushell
      pass
      pciutils
      usbutils
      vim
      wget
      zoxide
    ];
  };

  xen = { ... }:
  {
    networking.hostName = "xen";
    deployment = {
      targetHost = "100.85.206.102";
      targetUser = "root";
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
      targetHost = "100.75.154.28";
      targetUser = "root";
      tags = [ "domu" ];
    };
    imports = [
      ./hosts/nas-configuration.nix
      ./common/remote.nix
      ./common/xen_domU.nix
    ];
  };
}
