#!/usr/bin/env bash
# Local deployment helper: authenticates to OpenBao with the colmena-app
# AppRole, then runs `colmena apply` so the `deployment.keys` in hive.nix
# can fetch their values via `keyCommand`.
#
# Requirements:
#   - colmena, bao, jq installed
#   - pass entries: bao/approle/colmena-role-id, bao/approle/colmena-secret-id
#
# Usage (all colmena args are passed through):
#   ./deploy.sh                          # apply to all nodes
#   ./deploy.sh --reboot --on @domu      # like the CI workflow
#   ./deploy.sh boot --on @dom0
set -euo pipefail

export BAO_ADDR="${BAO_ADDR:-https://bao.dadatoa.net}"

COLOMENA_ROLE_ID="${COLOMENA_ROLE_ID:-$(pass show bao/approle/colmena-role-id)}"
COLOMENA_SECRET_ID="${COLOMENA_SECRET_ID:-$(pass show bao/approle/colmena-secret-id)}"

if [ -z "$COLOMENA_ROLE_ID" ] || [ -z "$COLOMENA_SECRET_ID" ]; then
  echo "error: missing colmena-app credentials (pass entries bao/approle/colmena-role-id / colmena-secret-id)" >&2
  exit 1
fi

info() { printf '\n== %s ==\n' "$*"; }

info "login to OpenBao with colmena-app AppRole"
export BAO_TOKEN="$(bao write -format=json auth/approle/login \
  role_id="$COLOMENA_ROLE_ID" secret_id="$COLOMENA_SECRET_ID" \
  | jq -er '.auth.client_token')"

info "colmena apply"
exec colmena apply -f colmena/hive.nix "$@"
