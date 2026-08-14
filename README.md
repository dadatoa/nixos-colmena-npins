[![deploy nixos configurations](https://github.com/dadatoa/nixos-colmena-npins/actions/workflows/deployment.yml/badge.svg)](https://github.com/dadatoa/nixos-colmena-npins/actions/workflows/deployment.yml)

# Homelab - Partie Nixos

Base de mon Homelab. Hyperviseur Xen avec *Nixos* comme Dom0** + nas virtualisé *Nixos* ( hostname `nas`). Le tout déployé avec *Colmena*. Je n'utilise pas *flake* pour la configuration, mais *npins* pour épingler les dépendances. *Colmena* ne peut pas bootstrap -> j'utilise *flake* pour bootstrap mes machines. 
 - pas *npins* pour bootstrap : j'ai 2 configuration de base : une pour Xen Hypervisor et une pour les VMs. *flake* permet d'avoir les 2 dans le même repo et de sélectinner celle que je veux à l'installation. Je ne sais pas faire ça avec *npins*
 - Pas *flake* pour la configuration des machine (après le bootstrap) : c'est un homelab, j'avais envie de tester autre chose.
 
La documentation est un fichier *emacs orgmode* -> permet de mettre toute le code dans la doc, puis de *tangle* vers les fichiers de configurations nix. Et j'avais envie d'essayer *emacs*. 
