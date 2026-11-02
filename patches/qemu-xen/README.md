# qemu-xen : patches pour le passthrough de l'iGPU Intel (IGD)

Ces deux patches rendent `gfx_passthru = 1` utilisable sur un dom0 qui expose le
VBIOS du iGPU comme *shadow ROM* (cas des cartes Intel, UHD 630 ici). Sans eux,
QEMU (device model du domaine) meurt à la création du domaine, donc
`xl create` échoue et le domaine reste en `--p---`.

Appliqués à QEMU 10.2.4 (`pkgs.qemu_xen`) via l'overlay `qemuXenIgdOverlay`
dans `colmena/hive.nix`.

## 0001 — écrire l'attribut sysfs `rom` en texte

`hw/xen/xen_pt_load_rom.c` écrivait un octet binaire `0x01` dans
`/sys/bus/pci/devices/0000:00:02.0/rom` pour activer la ROM. Depuis que
l'attribut est parsé par `kstrtobool()`, un octet binaire est refusé
(`-EINVAL`) : la ROM restait désactivée, la lecture renvoyait 0 octet et QEMU
abandonnait (`pci-assign: Cannot read from host ...`, puis
`VGA: VBIOS image corrupt (too small)` à cause d'un `bios_size` non initialisé).

Le patch écrit `"1"` / `"0"` comme du texte et met `ptr = NULL` quand la lecture
échoue, pour que l'appelant ne lise pas un buffer à moitié rempli.

## 0002 — ne pas enregistrer deux fois la BAR ROM de l'iGPU

Dans `hw/xen/xen_pt.c`, `xen_pt_register_regions()` enregistre la BAR
d'expansion ROM quand `d->rom.base_addr && d->rom.size`. Or pour un IGD en
passthrough, `xen_pt_setup_vga()` a déjà enregistré cette BAR (VBIOS lu depuis
sysfs puis copié en `0xc0000`). Le VBIOS du iGPU étant un shadow ROM
(`0xc0000-0xdffff`, `IORESOURCE_ROM_SHADOW`), les deux champs sont renseignés
et le second enregistrement déclenche :

    qemu-system-i386: ../hw/pci/pci.c:1497: pci_register_bar:
    Assertion `!r->size' failed.

Le patch saute l'enregistrement quand `is_igd_vga_passthrough(d)`.

## Vérification

Testés avec `patch -p1 --dry-run` sur l'arbre source exact de
`pkgs.qemu_xen.src` (`qemu-10.2.4.tar.xz`). Les deux bugs existent toujours
dans QEMU master : ces patches sont à revoir à chaque montée de version de
`qemu_xen` (si un patch ne s'applique plus, le build casse — c'est volontaire).
