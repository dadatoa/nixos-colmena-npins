# variables
target:="xen.blue-edmontosaurus.ts.net"
user:="operateur"
vg:="nvme_vg"
branch:="main"

create_disk machine size:
  ssh {{user}}@{{target}} "sudo lvcreate --name {{machine}} --size {{size}} {{vg}}"
  ssh {{user}}@{{target}} "sudo mkfs.btrfs /dev/{{vg}}/{{machine}}"

prepare_disk machine:
  ssh {{user}}@{{target}} "sudo mkdir -p /mnt"
  ssh {{user}}@{{target}} "sudo mount -t btrfs /dev/{{vg}}/{{machine}} /mnt"
  ssh {{user}}@{{target}} "sudo btrfs subvolume create /mnt/boot; \
    sudo btrfs subvolume create /mnt/nix; \
    sudo btrfs subvolume create /mnt/persistent"

send_config:
  ssh {{user}}@{{target}} -t "git init --bare homelab.git"
  git push ssh://{{user}}@{{target}}/home/{{user}}/homelab.git {{branch}}
  ssh {{user}}@{{target}} "cd homelab.git; git worktree add {{branch}}"

