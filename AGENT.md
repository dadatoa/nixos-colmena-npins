# AGENT.md — nixos-colmena-npins

> Homelab NixOS repo: Xen hypervisor (dom0) + NixOS VMs (domU) deployed via **Colmena** (npins, flakeless) after initial **Flake** bootstrap. Impermanent (`preservation` + tmpfs `/`) on Btrfs. Secrets via **OpenBao** (`bao` AppRole + `deployment.keys`). Single source of truth is `documentation.org` (Emacs Org `tangle`).

## 1. Project Overview

- **Goal:** Declare and deploy a Xen-based homelab: `xen` (dom0, bare metal) and `nas` (domU, PVH guest) today, extensible to more domUs. Also defines Alpine VM `alp-dns1` via `xl` config only.
- **OS:** NixOS `nixos-26.05` (pinned), plus `nixos-unstable` overlay (`pkgs.unstable.*`).
- **Hypervisor:** Xen Project, dom0 = PVH, guests = PVH + `grub-xen_pvh`.
- **Deploy tool:** [Colmena](https://colmena.cli.rs/) in flakeless mode (`colmena/hive.nix` + `npins/sources.json`), not `flake.nix`.
- **Bootstrap:** `flake.nix` + `flake/` only to *install* a machine the first time (`nixos-install` with `xen` or `nixdomu` config). Day-2 management is Colmena.
- **Impermanence:** `nix-community/preservation` — root `/` is `tmpfs`, state in `/persist` (Btrfs subvolumes, Disko on bootstrap).
- **Networking:** `systemd-networkd` everywhere. Xen bridges `xenbr0` (LAN), `xenbr50`/`xenbr66` (VLAN 50/66 isolated, no dom0 IP, vlan sub-interfaces `enp2s0.50`/`.66`). Guests use `enX0` + DHCP. Firewall disabled (assumes homelab). Tailscale (`pkgs.unstable.tailscale`) + Avahi/mDNS + OpenSSH.
- **Locale:** `fr_FR.UTF-8`, `Asia/Bangkok`.
- **Secrets:** OpenBao at `https://bao.dadatoa.net`. Colmena `deployment.keys` with `keyCommand = [ "bao" "kv" "get" ... ]` → `/persist/keys` (and `/run/keys`). Needs `BAO_ADDR` + `BAO_TOKEN` (AppRole `colmena-app`). Local: `deploy.sh`. CI: GitHub Actions + Tailscale `tag:cicd`.

## 2. Repository Layout

```
flake.nix              # Bootstrap flake (flake-parts): nixosConfigurations.{xen,nixdomu}
flake/                 # Flake modules: shared (common/) + xen-config/ + vm-config/
  common/              #  administration.nix, localisation.nix, remote_access.nix, settings.nix, usefull_tools.nix, users/
  xen-config/          #  configuration.nix, disko.nix, filesystems.nix, preservation.nix  (dom0 bootstrap)
  vm-config/           #  configuration.nix, filesystems.nix, networking.nix, preservation.nix (domU bootstrap)
colmena/               # Day-2 configs (flakeless, npins-based)
  hive.nix             # Hive: meta.nixpkgs/specialArgs, defaults, nodes {xen,nas}
  common/              #  locale.nix, users.nix, preservation.nix, remote.nix, xen_domU.nix, docker.nix, proton-vpn.nix, technitium.nix
  hosts/               #  xen-configuration.nix, nas-configuration.nix (+ xen/ subdir: disko etc., currently unused by hive)
npins/                 # Pins: sources.json + default.nix (nixpkgs 26.05, unstable, disko, preservation, herdr-nix)
xl_configs/            # Xen xl domain configs: xen.cfg, nas.cfg, alp-dns1.cfg  (kernel = /run/current-system/.../grub-i386-xen_pvh.bin)
alpine/                #  reboot_if.sh
documentation.org      # *** SOURCE OF TRUTH — org-mode literate file that tangles to colmena/**/*.nix + xl_configs/*.cfg
deploy.sh              # Local deploy helper: pass→bao AppRole login → `colmena apply -f colmena/hive.nix`
test-colmena-approle.sh# Verify colmena-app AppRole capabilities against OpenBao (admin AppRole → mint secret-id)
.github/workflows/     # deployment.yml (colmena apply), deploy-domU.yml, deploy-keys.yml, unseal-openbao.yml, update-flake/npins.yml
```

## 3. Tech Stack & Pins

| Pin | Source | Purpose |
|-----|--------|---------|
| `nixpkgs` | `nixos-26.05` channel tarball | Stable base (also `meta.nixpkgs` in hive) |
| `unstable` | `nixos/nixpkgs nixos-unstable` | `pkgs.unstable.*` via `unstableOverlay` (e.g. `tailscale`, `jellyfin`) |
| `disko` | `nix-community/disko` | Disk partitioning (bootstrap + hive `defaults`) |
| `preservation` | `nix-community/preservation` | Impermanence (`preserveAt."/persist"`) |
| `herdr-nix` | `herdrdev/herdr-nix` | Pinned but not wired in `hive.nix` currently |

Global config: `allowUnfree = true`, `nix.channel.enable = false`, `experimental-features = nix-command flakes`, weekly GC `--delete-older-than 7d`, `nixpkgs.hostPlatform = "x86_64-linux"`, `system.stateVersion = "26.05"`.

## 4. Source of Truth — `documentation.org`

- **Do not hand-edit** `colmena/**/*.nix` or `xl_configs/*.cfg` in isolation if you can avoid it: they are **tangled** from `documentation.org` (`#+begin_src nix :tangle <path> :noweb tangle`).
- Workflow for an LLM or human editor:
  1. Edit the relevant `#+begin_src ... :tangle ...` block in `documentation.org`.
  2. Tangle: `emacs --batch -l org documentation.org -f org-babel-tangle` (or `M-x org-babel-tangle` in Emacs).
  3. Verify diff on the generated `.nix`/`.cfg` files, then commit both.
- If you must quick-patch a `.nix` directly, **backport** the change to `documentation.org` immediately or it will be clobbered on next tangle.
- Noweb references: `<<hive-xen>>`, `<<hive-nas>>`, `<<xen-filesystem>>`, `<<xen-networking>>`, `<<xen-preserve>>`, `<<xen-cockpit>>`, `<<nas-cockpit>>`, `<<nas-containers>>`, etc.

## 5. Hosts

### `xen` — dom0 (bare metal)
- `colmena/hosts/xen-configuration.nix` + `colmena/common/remote.nix` + hive `defaults`.
- Systemd-boot, `linuxPackages_latest`, `intel_iommu=on`, `vfio_*` in initrd, `systemd.tpm2.enable = false`.
- `virtualisation.xen.enable = true`, `dom0Resources = { memory = 2048; maxVCPUs = 2; }`, `boot.params = [ "dom0=pvh" ]` (hive; bootstrap uses 1024 MiB).
- Filesystems (tmpfs `/`, vfat `/boot` `A39E-73FE`, Btrfs on `/dev/mapper/sys-dom0` subvols `@nix/@persist/@var`, swap `a6a0f0a7-...`).
- Networking: `xenbr0` bridged to `enp2s0` (+ DHCP), VLAN bridges `xenbr50/66` isolated, Cockpit `:9090`.
- Bins: `qemu_xen`, `grub2_xen*`, `colmena`.

### `nas` — domU (Xen PVH guest)
- `colmena/hosts/nas-configuration.nix` + `remote.nix` + `xen_domU.nix`.
- `xen_domU.nix`: GRUB `nodev`, `console=hvc0`, `xen-*front` kernelModules, `useNetworkd` `enX0` DHCP, `systemd.getty.autologinUser`, GlusterFS enabled (tmpfs `/` + Btrfs `/dev/xvda` subvols `nix/persist/boot/var`, 4 GiB swapfile).
- `nas-configuration.nix`: Gluster volumes (`/srv/gluster/chill` on `/dev/disk/by-label/media` + `/data/media` `glusterfs` mount), Jellyfin (`pkgs.unstable`), Cockpit `:9090` (`cockpit-podman`), Podman + `gluetun` OCI container (WireGuard → `protonvpn`, env from `/persist/keys/proton.key`, `NET_ADMIN` + `/dev/net/tun`).

### Xen guests (`xl_configs/`)
- `nas.cfg`: `pvh, 4096M, 2 vcpus, bridge=xenbr50 mac 02:b0:9a:91:34:40, disks /dev/sys/nas,/dev/rust/media,/dev/nvme_vg/appdata`.
- `alp-dns1.cfg`: `pvh, 512M, 1 vcpu, bridge=xenbr50 mac 90:FA:28:00:10:C9, VNC, disk /dev/sys/alp-dns1`. (Alpine, no NixOS hive entry.)

## 6. How to Work (Agent Guidelines)

### Editing
- Prefer editing `documentation.org` then tangling. If the task says "change X in colmena/...", apply the same change in both places or note the drift.
- Use `read` to inspect the tangle target before editing; keep `edits[].oldText` unique and minimal.
- Validate Nix: `nix-instantiate --parse <file>`, `nix flake check` (bootstrap), `colmena build -f colmena/hive.nix` or `colmena apply --dry-run`.
- Update pins with `npins update` (or `nix run github:nix-community/npins -- update`) — then adjust `hive.nix`/`modules` if API changed.

### Common Tasks
- **Add a host:** Add a `<<hive-<name>>>` noweb block + entry in `hive.nix` `xen`/`nas` style, create `colmena/hosts/<name>-configuration.nix`, add `xl_configs/<name>.cfg` if Xen, tangle, test `colmena build`.
- **Add shared config:** Create `colmena/common/<name>.nix`, import in `hive.nix:defaults.imports` (or per-host `imports`).
- **Add a secret:** Add `deployment.keys.<name>` in `hive.nix` `defaults` with `keyCommand = [ "bao" "kv" "get" "-field=<field>" "secrets/projects/colmena" ]`, set `destDir = "/persist/keys"` (+ `user`/`group` if needed), ensure the field exists in OpenBao, and add `preservation` handling if needed.
- **Bootstrap a new machine:** `nixos-generate-config` is not used — use `nixos-install --flake .#xen` (dom0) or `.#nixdomu` (domU) from a NixOS installer with this repo checked out.

### Deployment
- **Local (recommended):**
  ```bash
  ./deploy.sh                          # all nodes
  ./deploy.sh --on @dom0 --reboot      # only dom0, reboot
  ./deploy.sh --on @domu boot          # domU next boot
  ./deploy.sh --show-trace --dry-activate
  ```
  Requires `colmena`, `bao`, `jq`, `pass` entries `bao/approle/colmena-role-id` + `colmena-secret-id`, and `BAO_ADDR` (default `https://bao.dadatoa.net`). The script logs into OpenBao, exports `BAO_TOKEN`, then `exec colmena apply -f colmena/hive.nix`.
- **Verify secrets only:** `./test-colmena-approle.sh` (needs admin AppRole in `pass`).
- **CI:** Push → GitHub Actions `deployment.yml` / `deploy-domU.yml` / `deploy-keys.yml` (each: `unseal-openbao` → install Nix+Colmena+Bao → Tailscale `tag:cicd` → `bao write auth/approle/login` → `colmena apply/upload-keys`). Secrets: `OPENBAO_ADDR`, `COLMENA_APP_ROLE_ID/SECRET_ID`, `TS_OAUTH_*`, `SSH_USER/KEY`, `TS_TAILNET`.

### Networking & Remote
- Targets: `xen` → `100.85.206.102` (Tailscale), `nas` → `10.10.10.209` (VLAN 50). `targetUser = operateur` (`uid 1000`, `wheel`+`video`, `nushell`, passwordless sudo, polkit reboot/poweroff, `trusted-users`).
- Tags: `@dom0` (`xen`), `@domu` (`nas`). Use `colmena apply --on @domu` etc.
- `deployment.buildOnTarget = true`, `allowLocalDeployment = true`.

## 7. Conventions & Pitfalls

- **Language:** Docs/comments are French (`documentation.org`); keep new docs consistent or English with a note.
- **Impermanence:** Anything not under `preserveAt."/persist"` is lost on reboot (`/` is `tmpfs` on both dom0 and domU). Persist SSH host keys, `machine-id`, `xl` auto configs, user dotfiles via `preservation.nix`. Disko declares subvols — don't rename without updating both `flake/*/filesystems.nix` and `colmena/*/filesystems` blocks.
- **Btrfs + `growPartition = false`:** Required on `xen_domU.nix` to avoid `growpart.service` failure with impermanence.
- **Flake vs Colmena drift:** `flake/xen-config` and `flake/vm-config` are *bootstrap only* — they duplicate but intentionally diverge from `colmena/hosts/*` (e.g. simpler networking in bootstrap). Don't assume they stay in sync; update both if changing boot fundamentals. `disko.nix` only in bootstrap.
- **Unstable overlay:** Use `pkgs.unstable.<pkg>` (via `unstableOverlay`), not `sources.unstable` directly.
- **`deployment.keys`:** Values are fetched *at deploy time on the deployer* via `bao` — CI/local must have a valid `BAO_TOKEN`. `destDir = "/persist/keys"` so secrets survive reboot. Permissions via `user`/`group`.
- **Xen kernel path:** `xl_configs/*.cfg` hardcode `kernel="/run/current-system/sw/lib/grub-xen_pvh/grub-i386-xen_pvh.bin"` — depends on `grub2_xen_pvh` being in `environment.systemPackages`.
- **No `AGENTS.md` / `CLAUDE.md` yet:** This file is the canonical agent guide.

## 8. Useful Commands

```bash
# Tangle docs → nix
emacs --batch -l org documentation.org -f org-babel-tangle

# Eval / build (from repo root)
nix flake check
nix flake show
colmena build -f colmena/hive.nix
colmena apply -f colmena/hive.nix --dry-activate --show-trace
colmena exec -f colmena/hive.nix --on @dom0 -- lsblk -f
colmena upload-keys -f colmena/hive.nix --on @domu   # secrets only

# Pins
npins update
npins show
nix run github:nix-community/npins -- update

# Secrets / OpenBao
bao kv get secrets/projects/colmena
./test-colmena-approle.sh
bao token lookup -format=json | jq .data.policies

# Xen (on xen host)
xl list
xl create /etc/xen/auto/nas.cfg
xl console nas
journalctl -u xencommons -b
```

## 9. CI Workflows

- `deployment.yml` — full `colmena apply -f colmena/hive.nix` (all hosts).
- `deploy-domU.yml` — `colmena apply --reboot --on @domu`.
- `deploy-keys.yml` — `colmena upload-keys --on @domu`.
- `unseal-openbao.yml` — reusable; unseals Bao before deploy.
- `update-flake.yml` / `update-npins.yml` — bump inputs/pins.

## 10. When to Ask

- Changing `disko`/`preservation`/`filesystems`/`xen cfg` — risk of unbootable machine; propose `colmena build` + `--dry-activate` first.
- Adding/modifying `deployment.keys` — confirm the OpenBao field name and file ownership.
- Touching VLAN/bridge topology — dom0 and all `xl_configs` must agree; otherwise guests lose network.
