#!/usr/bin/env bash
# Verify that the colmena-app AppRole can read the KVv2 secret at
# secrets/projects/data/colmena (logical path secrets/projects/colmena).
#
# How it works:
#   1. logs in with the admin AppRole (credentials from pass)
#   2. reads colmena-app's role-id and mints a single-use secret-id
#   3. logs in as colmena-app
#   4. prints the token's effective capabilities on the secret path
#   5. reads the secret and prints only the key names (values are masked)
#
# Requirements: bao CLI, jq, and an unlocked pass store containing
#   bao/approle/admin-role-id and bao/approle/admin-secret-id
set -euo pipefail

export BAO_ADDR="${BAO_ADDR:-https://bao.dadatoa.net}"

info() { printf '\n== %s ==\n' "$*"; }

info "login as admin approle"
ADMIN_TOKEN="$(bao write -format=json auth/approle/login \
  role_id="$(pass show bao/approle/admin-role-id)" \
  secret_id="$(pass show bao/approle/admin-secret-id)" \
  | jq -er '.auth.client_token')"

info "read colmena-app role-id"
ROLE_ID="$(BAO_TOKEN="$ADMIN_TOKEN" bao read -format=json \
  auth/approle/role/colmena-app/role-id | jq -er '.data.role_id')"

info "mint a single-use secret-id for colmena-app"
SECRET_ID="$(BAO_TOKEN="$ADMIN_TOKEN" bao write -f -format=json \
  auth/approle/role/colmena-app/secret-id \
  secret_id_num_uses=1 secret_id_ttl=300 \
  | jq -er '.data.secret_id')"

info "login as colmena-app"
APP_TOKEN="$(bao write -format=json auth/approle/login \
  role_id="$ROLE_ID" secret_id="$SECRET_ID" | jq -er '.auth.client_token')"

info "policies attached to the colmena-app token"
BAO_TOKEN="$APP_TOKEN" bao token lookup -format=json \
  | jq -r '.data.policies[]'

info "effective capabilities on secrets/projects/data/colmena"
BAO_TOKEN="$APP_TOKEN" bao token capabilities secrets/projects/data/colmena

info "read the KVv2 secret (values masked)"
BAO_TOKEN="$APP_TOKEN" bao kv get -format=json secrets/projects/colmena \
  | jq '{readable: (.data.data != null), keys: (.data.data | keys)}'
