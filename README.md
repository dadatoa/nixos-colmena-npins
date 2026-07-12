# nixos-colmena-npins

Infrastructure-as-code for a small fleet of NixOS machines running under Xen.
Two complementary approaches live side by side: **flake-based configs** for
bootstrapping new machines, and **Colmena + npins** for ongoing management of
all machines at once without relying on flakes for deployment.

---

## Prerequisites

- **Nix** with `flakes` and `nix-commands` experimental features enabled
- **Colmena** — install via `nix profile install nixpkgs#colmena` or from
  your distro
- **npins** — install via `nix profile install nixpkgs#npins`
- **Tailscale** — all machines are connected over a Tailscale mesh VPN; you
  need to be on the same tailnet to deploy
- **SSH access** — your public key must be in the machine's
  `operateur` user (see `colmena/common/users.nix` and
  `flake/common/users/default_users.nix`)

---

## Approaches

### 1. Flake-based configs (`flake/`)

Used for **bootstrapping** new machines — initial installs and one-off builds.

- Defines `nixosConfigurations` for `xen` (dom0) and `nixdomu` (a reference
  Xen VM guest)
- Build with `nixos-install` using the top-level `flake.nix`

### 2. Colmena + npins (`colmena/`)

Used for **ongoing management** of all machines — deploy config changes to
every host in one shot.

- Colmena hive defines nodes: `xen`, `nas`, `deckard`, `giles`
- npins pins `nixpkgs` (26.05), `unstable`, `disko`, and `preservation`
  — no `flake.lock` needed for deployment
- CI/CD via GitHub Actions updates npins weekly and deploys automatically

---

## Machine Inventory

| Host     | Role              | Tags       | Target           |
|----------|-------------------|------------|------------------|
| `xen`    | Dom0 hypervisor   | `dom0`     | `100.107.28.98`  |
| `nas`    | DomU storage      | `domu`     | `100.70.23.23`   |
| `deckard`| DomU runner       | `domu`     | `100.127.50.22`  |
| `giles`  | DomU runner       | `domu`     | `100.82.170.70`  |

---

## Directory layout

```
flake.nix                     # top-level flake (flake-parts)
flake.lock
npins/
├── default.nix               # npins Nix library (auto-generated)
└── sources.json              # pinned sources (nixpkgs, unstable, disko, preservation)
flake/
├── default.nix               # flake outputs: nixosConfigurations
├── common/                   # shared modules (users, locale, remote access, tools)
├── vm-config/                # NixOS config for a Xen domU guest
└── xen-config/               # NixOS config for the Xen dom0 host
colmena/
├── hive.nix                  # colmena hive definition (all nodes + defaults)
├── common/                   # shared modules (locale, users, xen_domU)
└── hosts/
    ├── xen/                  # dom0 host config (disko, networking, boot)
    ├── nas/                  # domU storage host
    ├── deckard/              # domU runner host
    └── giles/                # domU runner host
.github/workflows/
├── update-npins.yml          # weekly npins update (& optional deploy)
├── deploy-domU.yml           # deploy to @domu hosts
├── deploy-dom0.yml           # deploy to @dom0 host (with --reboot)
└── deployment.yml            # combined domU → dom0 rollout
```

---

## Usage

### Bootstrap a new machine (flake)

#### Prepare Disks

I use [Disko](https://github.com/nix-community/disko) for bare metal hosts (only xen so far)

``` bash
# format and mount your drive(s)
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount /<path>/<to>/<your>/<disko>/<config> # can be relative Path

# install nix
sudo nixos-install --flake .#your-flake

```
For VMs, I just create a LVM Logical Volume (LV) which will be my root filesystem, as I use *btrfs* I eventually create the subvolumes that I need directly from dom0.

``` bash
sudo lvcreate --name my_filesystem_lv --size 10G my_vg

sudo mkfs.btrfs /dev/my_vg/my_filesystem_lv

# If I go with impermanence, I will need sub-volumes for /nix, /boot, and /persist
# in order to create subvolumes with btrfs, I need to mount the LV
sudo mount /dev/my_vg/my_filesystem_lv /mnt

# /persist can have any name, it is for keeping preserved files and dirs with preservation module
sudo btrfs subvolume create /mnt/nix
sudo btrfs subvolume create /mnt/boot
sudo btrfs subvolume create /mnt/persist

# As I want to have something clean with impermanence, I unmount <my_filesystem_lv>
# and I will mount each subvolume separately on /mnt
sudo umount /mnt
sudo mkdir /mnt/{nix boot persist}
sudo mount -t btrfs -o subvolume=boot /dev/my_vg/my_filesystem_lv /mnt/boot
sudo mount -t btrfs -o subvolume=nix /dev/my_vg/my_filesystem_lv /mnt/nix
sudo mount -t btrfs -o subvolume=persist /dev/my_vg/my_filesystem_lv /mnt/persist
```

#### Install the system

```bash
# Install Xen dom0
# launched from an installation media
nixos-install --flake .#xen

# Install a Xen VM
# can be executed directly on dom0
nixos-install --flake .#nixdomu
```

### Deploy with Colmena

```bash
# Deploy to all machines
colmena apply

# Deploy to domUs only (nas, deckard, giles)
colmena apply --tags domu

# Deploy to dom0 only (xen)
colmena apply --tags dom0

# Dry-run (build but don't activate)
colmena apply dry-activate
```

### Update pinned sources

```bash
cd npins
npins update

# Or let the weekly GitHub Actions workflow do it for you.
```

Commit the updated `npins/sources.json` and push — the deployment workflow
will apply the changes automatically.

---

## Key components

| Component      | Role                                                      |
|----------------|-----------------------------------------------------------|
| **disko**      | Declarative disk partitioning & formatting                |
| **preservation**| Impermanence-style state management (persist on /persist) |
| **Tailscale**  | Mesh VPN for secure interconnect between all machines     |
| **Avahi**      | mDNS for local service discovery                          |

---

## CI/CD Pipelines

- **`update-npins.yml`** — runs every Thursday at 21:00 UTC (or manually);
  runs `npins update`, commits the updated `sources.json`, and optionally
  triggers a deployment.
- **`deploy-domU.yml`** — manually triggered; deploys the current config to
  all `@domu` hosts.
- **`deploy-dom0.yml`** — manually triggered; deploys to `@dom0` with
  `--reboot`.
- **`deployment.yml`** — combines both in sequence: domU first, then dom0.
