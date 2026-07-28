current=$(uname -r)
last="$(ls /lib/modules)"
if [$current == $last]; then echo "no reboot"; else echo "reboot"; fi
