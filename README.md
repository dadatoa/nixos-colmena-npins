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
- Built with `nixos-rebuild` using the top-level `flake.nix`
- Pins are managed via `flake.lock`
- Best for: initial machine provisioning, testing config changes locally

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

```bash
# Install the Xen dom0
nixos install --flake "git+https://your-instance.fogejo.example/username/nixos-config#xen"
# Directly from my github repo
nixos install --flake github:dadatoa/nixos-colmena-npins#xen

# Build and activate the reference Xen VM
nixos install --flake "git+https://your-instance.fogejo.example/username/nixos-config#nixdomu"
# Directly from my github repo
nixos install --flake github:dadatoa/nixos-colmena-npins#xen

```

### Deploy with Colmena

```bash
# Deploy to all machines
colmena apply # add -f colmena/hive.nix if you are in the root dir

# Deploy to domUs only (nas, deckard, giles)
colmena apply --tags domu

# Deploy to dom0 only (xen)
colmena apply --tags dom0

# Dry-run (build but don't activate)
colmena apply dry-activate
```

### Update pinned sources

```bash
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
