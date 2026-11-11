# AGENT.md — nixos-colmena-npins

> Guide pour agents/outils IA. Dépôt de homelab NixOS basé sur **Xen** (dom0 + domU) géré en day-2 via **Colmena** en mode *flakeless* avec dépendances **npins**. Impermanence (`preservation` + `/` en `tmpfs`) et secrets via **OpenBao** (`deployment.keys`). La **source de vérité** des configurations générées est `documentation.org` (Emacs Org, *tangle*).

## 1. Vue d’ensemble

- **Objectif :** Déclarer et déployer un homelab Xen : `xen` (dom0, bare metal) et `nas` (domU PVH), extensible à d’autres domU. Des invités non-NixOS sont aussi décrits via `xl_configs/`.
- **OS :** NixOS `nixos-26.05` (pin npins) + overlay `nixos-unstable` exposé en `pkgs.unstable.*`.
- **Hyperviseur :** Xen Project. Dom0 en mode PVH ; invités PVH avec kernel `…/grub-xen_pvh/grub-i386-xen_pvh.bin` (fourni par `grub2_xen_pvh`).
- **Déploiement :** `colmena/hive.nix` + `npins/sources.json` (pas de flake de déploiement).
- **Bootstrap :** Le README/guide historique mentionne un bootstrap par flake (`.#xen`/`.#nixdomu`) ; **aucun `flake.nix` racine ni répertoire `flake/` n’est présent dans l’état actuel du dépôt**. Les changements de base (disques/boot) doivent être traités avec prudence sur les machines existantes.
- **Impermanence :** `nix-community/preservation` — état persistant sous `/persist`, racine éphémère (`tmpfs`) sur dom0 et domU.
- **Secrets :** OpenBao (`https://bao.dadatoa.net`). `deployment.keys` dans `colmena/hive.nix` exécutent `bao kv get -field=… secrets/projects/colmena` au moment du déploiement et déposent les secrets dans `/persist/keys` (et runtime `/run/keys`). Nécessite `BAO_ADDR`/`BAO_TOKEN` valides côté opérateur/CI.
- **Réseau :** `systemd-networkd` partout, `networking.firewall.enable = false` (contexte homelab). Accès distant via SSH, Tailscale (`pkgs.unstable.tailscale`, auth key depuis secret) et Avahi/mDNS.
- **Locale/système :** `fr_FR.UTF-8`, timezone `Asia/Bangkok`, `nixpkgs.hostPlatform = "x86_64-linux"`, `system.stateVersion = "26.05"`, `allowUnfree = true`, GC hebdo (`--delete-older-than 7d`), `nix-command flakes` activés, channels désactivés.

## 2. Structure du dépôt (état actuel)

```
colmena/
  hive.nix                     # Meta (nixpkgs stable + overlay unstable), defaults, nodes xen/nas, deployment.keys
  common/
    locale.nix                 # Locale/timezone/console
    preservation.nix           # Impermanence commune (/persist, machine-id, clés SSH, dotfiles operateur)
    remote.nix                 # SSH, Tailscale, Avahi, protections restartIfChanged (sshd/tailscale/networkd)
    users.nix                  # Utilisateurs (root/operateur), sudo/polkit, trusted-users, mots de passe depuis secrets
    xen_domU.nix               # Base domU: GRUB PVH, console hvc0, modules xen-*front, réseau enX0, FS tmpfs+Btrfs, swapfile
  hosts/
    xen-configuration.nix      # Dom0: boot Xen/systemd-boot, FS, réseau bridges/VLAN, NFS, Cockpit, configs xl auto
    nas-configuration.nix      # DomU: stockage/gluster, Cockpit, Podman+OCI stack media (gluetun/arr/qbittorrent)
npins/
  default.nix                  # Loader généré par npins
  sources.json                 # Pins des dépendances
xl_configs/                    # Configs xl: alp1.cfg, alp2.cfg, microos-pvh.cfg, microos.cfg, nas.cfg
alpine/
  reboot_if.sh
patches/
  qemu-xen
.github/
  workflows/
    deploy-keys.yml
    deployment.yml
    unseal-openbao.yml
    update-npins.yml
  scripts/
    reboot-if-needed.sh        # Reboot conditionnel si kernel/config activée diffère du kernel courant
documentation.org              # Source littérale (tangle -> colmena/**/*.nix, xl_configs/*.cfg, etc.)
AGENT.md                       # Ce guide
README.md
.gitignore
```

**Note :** les fichiers d’aide au déploiement local mentionnés historiquement (`deploy.sh`, `test-colmena-approle.sh`) ne sont pas présents à la racine actuellement.

## 3. Stack technique & pins (`npins/sources.json`)

| Pin | Source | Rôle |
|-----|--------|------|
| `nixpkgs` | canal `nixos-26.05` | Base stable (`meta.nixpkgs` de la hive) |
| `unstable` | `nixos/nixpkgs` `nixos-unstable` | Paquets via `pkgs.unstable.*` |
| `disko` | `nix-community/disko` | Module importé dans `defaults` (partitionnement déclaratif) |
| `preservation` | `nix-community/preservation` | Module d’impermanence importé dans `defaults` |
| `herdr-nix` | `herdrdev/herdr-nix` | Épinglé, non utilisé dans `hive.nix` actuellement |

`colmena/hive.nix` définit un overlay `unstableOverlay` et un correctif ciblé (`opencodeNodeModulesHashFix`) appliqué uniquement à `opencode 2.2.5` du snapshot unstable épinglé (devient inerte après mise à jour du pin).

## 4. Source de vérité — `documentation.org`

- `documentation.org` est la **source principale** (Org-mode, `#+begin_src … :tangle <path> :noweb tangle`, références noweb comme `<<hive-xen>>`, `<<hive-nas>>`, etc.).
- **Workflow recommandé :**
  1. Modifier le bloc concerné dans `documentation.org`.
  2. Tangler : `emacs --batch -l org documentation.org -f org-babel-tangle` (ou `M-x org-babel-tangle`).
  3. Vérifier le diff des fichiers générés (`.nix`/`.cfg`) et committer source + sorties.
- Si un fichier généré est modifié directement, **rétroporter** le changement dans `documentation.org` pour éviter l’écrasement au prochain tangle.
- Certains fichiers de configuration peuvent diverger temporairement de la doc ; signaler la dérive si elle ne peut pas être résorbée immédiatement.

## 5. Hôtes Colmena

### `xen` — dom0 (tag `@dom0`, cible `root@100.85.206.102`)
- Imports : `./hosts/xen-configuration.nix`, `./common/remote.nix` (+ `defaults`: locale/users/preservation, disko, preservation).
- **Boot/Hyperviseur :** `systemd-boot` UEFI, initrd systemd, `linuxPackages_latest`, TPM2 désactivé, modules initrd `vendor_reset`, `vfio*`, `nbd`, `intel_iommu=on`. `virtualisation.xen.enable = true` (PVH dom0, `dom0Resources` 2048 MiB / 2 vCPU, `iommu=on`). `xendomains` démarre après `systemd-networkd`.
- **Stockage :** `/` tmpfs (25%), `/boot` vfat (`A39E-73FE`), Btrfs `/dev/mapper/sys-dom0` (`@nix`, `@persist`, `@var`), `/data/vm` ext4 (`/dev/mapper/sys-vm`), swap `a6a0f0a7-f380-496e-b341-65466510ffca`.
- **Réseau :** `xenbr0` ponté sur `enp3s0` (DHCP), VLAN `enp3s0.50`/`enp3s0.66` vers ponts isolés `xenbr50`/`xenbr66` (sans IP/link-local sur dom0). NFS serveur exporte `/data/vm` vers `10.10.10.0/24`.
- **Services/outils :** Cockpit `:9090` (+ `cockpit-files`, `cockpit-podman`, `udisks2`), paquets Xen/OVMF/grub_xen/Colmena/cdrkit/`pkgs.unstable.opencode`, service `vendor-reset-wx2100`.
- **Configs xl persistées/générées :** `environment.etc."xen/auto/alp1.cfg"` et `.../nas.cfg` (avec `preservation` de `/etc/xen/auto`).

### `nas` — domU PVH (tag `@domu`, cible `root@100.75.154.28`)
- Imports : `./hosts/nas-configuration.nix`, `./common/remote.nix`, `./common/xen_domU.nix`.
- **Base domU (`xen_domU.nix`) :** GRUB `nodev`, `console=hvc0`, `growPartition = false`, modules `xen-*front`, réseau `enX0` DHCP, autologin `operateur`, `services.glusterfs.enable = true`. FS : `/` tmpfs, `/dev/xvda` Btrfs (`nix`, `persist`, `boot`, `var`), swapfile 4 Gio `/persist/swapfile`.
- **Hôte (`nas-configuration.nix`) :** montages `/srv/gluster/chill` et `/data/media` (Btrfs, label `media`), Cockpit `:9090`, `virtualisation.podman`/OCI (backend podman, user `operateur`, linger). Stack conteneurs (réseau `7seas`, la plupart en `userns=keep-id`) :
  - `gluetun` (ProtonVPN WireGuard, `NET_ADMIN`, `/dev/net/tun`, env depuis `/persist/keys/proton.key`, ports 8080/6881),
  - `qbittorrent` (réseau via `container:gluetun`, volumes + `/data/media`),
  - `prowlarr`, `radarr`, `sonarr`, `flaresolverr` (images `lscr.io/linuxserver/*`, `ghcr.io/flaresolverr/flaresolverr`).
- **Paquets notables :** `colmena`, `pkgs.unstable.jellyfin*`.

### Invités Xen (`xl_configs/`)
- `nas.cfg` : PVH, 4096 MiB, 2 vCPU, `bridge=xenbr50` MAC `02:b0:9a:91:34:40`, disques `/dev/sys/nas,,xvda`, `/dev/rust/media,,xvdb`, restart on reboot/crash.
- `alp1.cfg`, `alp2.cfg`, `microos-pvh.cfg`, `microos.cfg` : autres définitions d’invités (certaines avec VNC) ; noms/usage à vérifier avant modification.
- Les chemins kernel `xl` dépendent de la présence de `grub2_xen_pvh` sur le dom0.

## 6. Secrets & déploiement

- **`deployment.keys` (hive, defaults) :** `root_password_hash`, `operateur_password_hash`, `ts_secret`, `proton.key`, `approle_id`, `approle_secret` — tous lus depuis `secrets/projects/colmena` dans OpenBao, `destDir = "/persist/keys"` (certains avec `user`/`group`).
- **Accès Colmena :** `deployment.buildOnTarget = true`, `deployment.allowLocalDeployment = true`, `targetUser = "root"` sur les nœuds actuels.
- **CI (GitHub Actions) :**
  - `deployment.yml` : apply `switch` puis reboot conditionnel via `.github/scripts/reboot-if-needed.sh` (`@domu` à chaque run ; `@dom0` uniquement si input `reboot-dom0`).
  - `deploy-keys.yml` : upload des clés.
  - `unseal-openbao.yml` : workflow réutilisable de déseal.
  - `update-npins.yml` : mise à jour des pins.
- **Exécution locale type :** exiger `colmena`, `bao` (et accès OpenBao/Tailscale/SSH selon la cible), puis `colmena apply -f colmena/hive.nix` (avec options `--on @dom0|@domu`, `--dry-activate`, `switch`, `upload-keys`, etc.) après authentification AppRole.

## 7. Commandes utiles

```bash
# Tangle documentation -> fichiers générés
emacs --batch -l org documentation.org -f org-babel-tangle

# Évaluation / build / dry-run
nix-instantiate --parse colmena/hive.nix
colmena build -f colmena/hive.nix
colmena apply -f colmena/hive.nix --dry-activate --show-trace
colmena apply -f colmena/hive.nix switch --on @domu
colmena upload-keys -f colmena/hive.nix
colmena exec -f colmena/hive.nix --on @dom0 -- xl list

# Pins
npins show
npins update
# ou: nix run github:nix-community/npins -- update

# Secrets
bao kv get secrets/projects/colmena
```

## 8. Conventions & pièges

- **Impermanence :** tout ce qui n’est pas sous `preserveAt."/persist"` (ou déclaré persistant) disparaît au reboot. Vérifier la persistance des clés SSH, `machine-id`, données applicatives/conteneurs, configs Xen auto, etc.
- **Source de vérité :** privilégier les edits dans `documentation.org` + tangle ; éviter la dérive durable entre doc et `.nix/.cfg`.
- **DomU Btrfs :** `growPartition = false` requis (voir `xen_domU.nix`) pour éviter les échecs liés à l’impermanence.
- **Overlay unstable :** utiliser `pkgs.unstable.<pkg>` (cohérent avec la config de base), pas d’import direct ad hoc.
- **Secrets :** les `keyCommand` s’exécutent côté déploiement — pas de token OpenBao valide = échec fetch/upload des clés. Vérifier nom de champ, permissions (`user`/`group`) et persistance.
- **Réseau/Xen :** la topologie bridges/VLAN du dom0 (`xenbr0/50/66`, VLAN sur `enp3s0`) doit correspondre aux `vif`/`bridge` des configs `xl` et aux attentes réseau des domU ; un écart peut couper le réseau invité.
- **Modifs risquées :** changements `disko`/filesystems/preservation/boot/Xen peuvent rendre une machine non bootable — privilégier `colmena build` + `--dry-activate` et revue attentive avant apply/reboot.

## 9. Quand demander confirmation

- Toucher au partitionnement, aux sous-volumes, à `preservation`, au bootloader/Xen ou aux configs `xl` critiques.
- Ajouter/modifier des secrets OpenBao (nom de champ, consommateurs, droits fichier).
- Modifier la topologie réseau (bridges, VLAN, interfaces physiques, MAC/bridge des invités).
- Introduire un écart intentionnel entre `documentation.org` et les fichiers générés.
