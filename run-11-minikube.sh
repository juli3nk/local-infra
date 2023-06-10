#!/usr/bin/env bash

LOCAL_IP_KIND="$(jq -r '.ip_addresses.kind.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"
LOCAL_CA_CERTS="/etc/ssl/certs/ca-certificates.crt"

KIND_CONFIG_PATH="config/kind/config.yml"
TMP_KIND_CONF_FILE_PATH="/tmp/kind-config.yml"


minikube start --embed-certs
