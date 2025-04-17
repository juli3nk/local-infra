#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"

MINIO_VERSION="$(jq -r 'minio' ${HOME}/.config/local/versions.json)"

LOCAL_IP_CLOUD="$(jq -r '.ip_addresses.cloud.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"
LOCAL_DATA_PATH="${HOME}/Data/minio"

NAME="minio"
NAME_CONSOLE="console"

CONTAINER_NAME="$NAME"
CONTAINER_NETWORK_EXTERNAL="external"

DNS_RECORD="${NAME}.${LOCAL_DOMAIN}"
DNS_RECORD_CONSOLE="${NAME_CONSOLE}.${NAME}.${LOCAL_DOMAIN}"

TRAEFIK_ROUTER_NAME="$NAME"
TRAEFIK_ROUTER_NAME_CONSOLE="$NAME_CONSOLE"
TRAEFIK_CERT_RESOLVER_NAME="stepca"

start() {
  mkdir -p "$LOCAL_DATA_PATH"

  docker container run \
    -d \
    --rm \
    --network "$CONTAINER_NETWORK_EXTERNAL" \
    --label "localnet.dns.minio.domain=${DNS_RECORD}" \
    --label "localnet.dns.minio.answer=${LOCAL_IP_CLOUD}" \
    --label "localnet.dns.console.domain=${DNS_RECORD_CONSOLE}" \
    --label "localnet.dns.console.answer=${LOCAL_IP_CLOUD}" \
    --label "traefik.enable=true" \
    --label "tag=app-external" \
    --label "traefik.docker.network=${CONTAINER_NETWORK_EXTERNAL}" \
    --label "traefik.http.services.${TRAEFIK_ROUTER_NAME}.loadbalancer.server.port=9000" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.service=${NAME}" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.rule=Host(\`${DNS_RECORD}\`)" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.entrypoints=https" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls=true" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
    --label "traefik.http.services.${TRAEFIK_ROUTER_CONSOLE_NAME}.loadbalancer.server.port=9001" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_CONSOLE_NAME}.service=${NAME_CONSOLE}" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_CONSOLE_NAME}.rule=Host(\`${DNS_RECORD_CONSOLE}\`)" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_CONSOLE_NAME}.entrypoints=https" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_CONSOLE_NAME}.tls=true" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_CONSOLE_NAME}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
    --name "$CONTAINER_NAME" \
    quay.io/minio/minio:"$MINIO_VERSION" \
      server \
      /data \
      --console-address ":9001"
}

stop() {
  docker container stop "$CONTAINER_NAME"
}

function usage() {
  echo "Usage: $0 {start|stop}"
  exit 1
}

case "$ACTION" in
  start)   start ;;
  stop)    stop ;;
  *)       usage ;;
esac
