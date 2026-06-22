# nixos-colmena-npins

A flakeless NixOS deployment using [colmena](https://github.com/zhaofengli/colmena)
for deployment and [npins](https://github.com/andir/npins) for dependency pinning.

The system tracks a **stable** nixpkgs channel, while specific packages are pulled
from **nixos-unstable** via an overlay exposed as `pkgs.unstable.*`.

## Layout

```
.
├── npins/            # pinned sources (nixpkgs, disko, preservation)
├── hive.nix          # colmena entrypoint (defines the unstable overlay + nodes)
├── common/           # shared modules applied to every node
│   ├── locale.nix    # French localization (locale, timezone, keyboard)
│   └── users.nix     # shared "operateur" user (passwordless sudo, power mgmt)
└── hosts/            # per-node NixOS modules
    ├── web01.nix
    ├── db01.nix
    └── xen.nix       # Xen hypervisor dom0
```

## Disko & Preservation

[disko](https://github.com/nix-community/disko) (declarative disk partitioning)
and [preservation](https://github.com/nix-community/preservation) (persistent
state on tmpfs-root setups) are pinned via npins and imported in `hive.nix`
`defaults`, so their NixOS options are available on **every node**.

Per-host disk layouts go in `hosts/<node>/disko.nix` and preservation rules in
`hosts/<node>/preservation.nix` (see `hosts/xen/` for an example).

## Xen hypervisor host

`hosts/xen.nix` (node `xen`, tag `hypervisor`) runs as a Xen type-1 hypervisor
with NixOS as dom0 (`virtualisation.xen.enable`). On nixos-26.05 the Xen module
requires **systemd-boot** (or Lanzaboote/Limine) plus a systemd-based initrd, so
unlike the GRUB-based hosts this node boots via UEFI. Attach the real uplink to
`xenbr0` and replace the placeholder filesystems with the target's
`hardware-configuration.nix`.

## Localization (French)

`common/locale.nix` is imported from `hive.nix`'s `defaults`, so every node is
localised in French:

- `i18n.defaultLocale` and all `LC_*` categories set to `fr_FR.UTF-8`
- `time.timeZone = "Asia/Bangkok"`
- `console.keyMap = "fr"` and `services.xserver.xkb.layout = "fr"`

To localise a single node differently, override these options in its
`hosts/*.nix` module.

## Shared user

`common/users.nix` defines an `operateur` account (uid `1000`) on every node:

- passwordless `sudo` (scoped to `operateur` via `security.sudo.extraRules`)
- may `reboot`/`poweroff` without sudo, via a polkit rule

No password or SSH key is set by default — add one so the account can log in,
e.g. `users.users.operateur.openssh.authorizedKeys.keys = [ "ssh-ed25519 ..." ]`.

## How stable + unstable works

`hive.nix` pins the base system to the stable channel (`meta.nixpkgs`) and defines
an overlay that imports the unstable channel with the same `system`/`config`:

```nix
unstableOverlay = final: prev: {
  unstable = import sources.unstable {
    inherit (prev) system;
    config = prev.config;
  };
};
```

In any host module you then mix channels explicitly:

```nix
environment.systemPackages = [
  pkgs.htop            # stable
  pkgs.unstable.neovim # unstable
];

services.caddy.package = pkgs.unstable.caddy;  # unstable package, stable module
```

The system `stateVersion` stays on the stable release; only the chosen packages
come from unstable.

## Usage

```bash
# enter a shell with the tools
nix-shell -p npins colmena

# update pins (commit npins/sources.json afterwards)
npins update             # both channels
npins update unstable    # just unstable

# build all node configurations (no deploy)
colmena build

# deploy
colmena apply            # build + push + switch on all nodes
colmena apply --on @web  # only nodes tagged "web"
colmena apply build --on web01
```

> The `hosts/*.nix` filesystem/bootloader settings are placeholders so the config
> evaluates. Replace them with each target's real `hardware-configuration.nix`.
