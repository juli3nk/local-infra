#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"

LOCAL_IP_KIND="$(jq -r '.ip_addresses.kind.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"
LOCAL_CA_CERTS="/etc/ssl/certs/ca-certificates.crt"

KIND_CONFIG_PATH="config/kind/config.yml"
TMP_KIND_CONF_FILE_PATH="/tmp/kind-config.yml"


sed \
	-e "s#%%LOCAL_CA_CERTS%%#${LOCAL_CA_CERTS}#" \
	-e "s/%%LOCAL_IP%%/${LOCAL_IP_KIND}/" \
	"$KIND_CONFIG_PATH" > "$TMP_KIND_CONF_FILE_PATH"

kind create cluster --config "$TMP_KIND_CONF_FILE_PATH"

rm -f "$TMP_KIND_CONF_FILE_PATH"
