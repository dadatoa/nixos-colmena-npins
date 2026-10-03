#!/usr/bin/env bash
#
# Reboot a deployed node, but only if the new configuration actually needs it.
#
# `colmena apply switch` activates the new configuration but keeps the old
# kernel running: `uname -r` still reports the previous kernel until the machine
# is rebooted. This script compares the running kernel with the kernel shipped by
# the configuration that was just activated (/run/current-system) and only
# reboots when they differ, or when the activation left /run/reboot-needed behind
# (same heuristic as nixos-rebuild's `switch`, and as alpine/reboot_if.sh).
#
# Colmena's own `--reboot` flag is deliberately not used: it reboots
# unconditionally (and even switches the goal to `boot`), and it gives no way to
# treat the dom0 differently from the domU guests, while rebooting xen restarts
# every running domU.
#
# usage: reboot-if-needed.sh <label> <host> [timeout-seconds]

set -euo pipefail

label=${1:?usage: reboot-if-needed.sh <label> <host> [timeout-seconds]}
host=${2:?usage: reboot-if-needed.sh <label> <host> [timeout-seconds]}
timeout=${3:-600}

ssh_opts=(-o LogLevel=ERROR -o ConnectTimeout=15)

log() { printf '%s: %s\n' "$label" "$*"; }
die() { printf '%s: error: %s\n' "$label" "$*" >&2; exit 1; }

# Ask the node what the activated configuration expects, and what is running.
probe=$(ssh "${ssh_opts[@]}" "$host" 'bash -s' <<'REMOTE' || die "cannot probe $host over SSH"
set -euo pipefail

# Kernel modules shipped by the configuration that is currently activated.
activated=""
for modules in /run/current-system/kernel-modules/lib/modules/* /run/current-system/sw/lib/modules/*; do
  [ -d "$modules" ] || continue
  activated=${modules##*/}
  break
done

running=$(uname -r)

if [ -z "$activated" ]; then
  verdict=unknown
elif [ -e /run/reboot-needed ]; then
  verdict=reboot-needed
elif [ "$running" = "$activated" ]; then
  verdict=current
else
  verdict=stale
fi

printf 'verdict=%s\nkernel=%s\nrunning=%s\n' "$verdict" "${activated:-unknown}" "$running"
REMOTE
)

verdict= kernel=unknown running=unknown
while IFS='=' read -r key value; do
  case $key in
    verdict) verdict=$value ;;
    kernel) kernel=$value ;;
    running) running=$value ;;
  esac
done <<<"$probe"

case $verdict in
  current)
    log "kernel $kernel is already running on $host: nothing to reboot"
    exit 0
    ;;
  stale)
    log "kernel changed on $host (running $running, activated $kernel): rebooting"
    ;;
  reboot-needed)
    log "activation of $host requested a reboot (running $running, activated $kernel): rebooting"
    ;;
  *)
    log "could not read the activated kernel of $host: skipping reboot"
    exit 0
    ;;
esac

# The connection is expected to die while the machine goes down.
ssh "${ssh_opts[@]}" "$host" 'bash -s' <<'REMOTE' || true
set -euo pipefail
if [ "$(id -u)" -eq 0 ]; then
  systemctl reboot
else
  sudo -n systemctl reboot
fi
REMOTE

# The reboot is only under way once the node stops answering.
went_down=false
for ((i = 0; i < 30; i++)); do
  if ! ssh -o LogLevel=ERROR -o ConnectTimeout=5 "$host" true >/dev/null 2>&1; then
    went_down=true
    break
  fi
  sleep 2
done
$went_down || die "$host still answers after the reboot was requested: check that the deploy user may reboot"

log "waiting up to ${timeout}s for $host to come back"
up=false
deadline=$((SECONDS + timeout))
while [ "$SECONDS" -lt "$deadline" ]; do
  if ssh -o LogLevel=ERROR -o ConnectTimeout=10 "$host" true >/dev/null 2>&1; then
    up=true
    break
  fi
  sleep 5
done
$up || die "$host did not come back within ${timeout}s after the reboot"

# tail -n1 to drop the login banner the remote sshd may print on stdout.
new_kernel=$(ssh "${ssh_opts[@]}" "$host" 'uname -r' 2>/dev/null | tail -n1 | tr -d '[:space:]') || true
[ "$new_kernel" = "$kernel" ] ||
  die "$host came back on kernel $new_kernel, expected $kernel"
log "$host is back up on kernel $new_kernel"
