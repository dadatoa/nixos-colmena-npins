[![deploy nixos configurations](https://github.com/dadatoa/nixos-colmena-npins/actions/workflows/deployment.yml/badge.svg)](https://github.com/dadatoa/nixos-colmena-npins/actions/workflows/deployment.yml)

# Homelab - Partie Nixos

## TLDR

- Flake -> bootstrap des system:
  - -> xen-config : pour l'hyperviseur xen
  - -> vm-config : pour les domU
- Colmena -> configurations des systèmes en utilisant nixos colmena pour tout déployer
- xl_configs -> fichiers .cfg pour démarrer les vm xen
- npins -> systeme de pin des dépendance nix utilisé avec colmena (colmena config flakeless)

## Intro

Base de mon Homelab. Hyperviseur Xen avec *Nixos* comme *Dom0* + nas virtualisé *Nixos* ( hostname `nas`). Le tout déployé avec *Colmena*. Je n'utilise pas *flake* pour la configuration, mais *npins* pour épingler les dépendances. *Colmena* ne peut pas bootstrap -> j'utilise *flake* pour bootstrap mes machines. 
 - pas *npins* pour bootstrap : j'ai 2 configuration de base : une pour Xen Hypervisor et une pour les VMs. *flake* permet d'avoir les 2 dans le même repo et de sélectinner celle que je veux à l'installation. Je ne sais pas faire ça avec *npins*
 - Pas *flake* pour la configuration des machine (après le bootstrap) : c'est un homelab, j'avais envie de tester autre chose.
 
La documentation est un fichier *emacs orgmode* -> permet de mettre toute le code dans la doc, puis de *tangle* vers les fichiers de configurations nix. Et j'avais envie d'essayer *emacs*.

## Note concernat les vm

Les vm qui doivent se lancer à chaque reboot sont configurées das des fichier `.cfg` situés dans `/etc/xen/auto`. Afin de garder l'aspect déclaratif de nixos, je génère ces fichier directement dans la configuration, par exemple : 

``` nix
 environment.etc."xen/auto/microos.cfg".text = ''
    name = "microos"
    type = "pvh"
    kernel = "${pkgs.OVMF-xen.mergedFirmware}"
    vcpus = 2
    memory = 4096
    vif = [ "bridge=xenbr50,mac=00:16:3e:49:a2:58" ]
    vfb = [ "vnc=1,vnclisten=127.0.0.1,vncunused=1" ]
    on_poweroff = "destroy"
    disk = [ 'format=raw, vdev=xvda, access=rw, target=/dev/sys/microos' ]
  '';

```
Dans cet exemple, la variable `${pkgs.OVMF-xen.mergedFirmware}` permet de récupérer le chemin vers le binaire pkgs.OVMF-xen qui n'est pas linké dans `/run/current-system/`. Je garde ça là car la configuration de *microos* va changer pour permettre le passsage du GPU à la vm.
   
