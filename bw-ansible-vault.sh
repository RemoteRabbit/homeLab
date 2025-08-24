#! /bin/bash

set -e

BW_VAULT_ITEM_ID="ansible-homelab-vault"
BW_SESSION="$(bw unlock --raw)"

echo "$(bw get password ${BW_VAULT_ITEM_ID} --session ${BW_SESSION})"
