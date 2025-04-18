#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"

GOGS_VERSION="$(jq -r '.gogs' ${HOME}/.config/local/versions.json)"

LOCAL_IP_CLOUD="$(jq -r '.ip_addresses.cloud.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"
LOCAL_DATA_PATH="${HOME}/Data/gogs"

NAME="git"

CONTAINER_IMAGE="docker.io/gogs/gogs"
CONTAINER_NAME="$NAME"
CONTAINER_NETWORK_EXTERNAL="external"

DNS_RECORD="${NAME}.${LOCAL_DOMAIN}"

TRAEFIK_ROUTER_NAME="$NAME"
TRAEFIK_CERT_RESOLVER_NAME="stepca"

start() {
  mkdir -p "$LOCAL_DATA_PATH"

  docker container run \
    -d \
    --rm \
    --mount type=bind,src="${LOCAL_DATA_PATH}",dst=/data \
    --network "$CONTAINER_NETWORK_NAME" \
    --publish "${LOCAL_IP_CLOUD}":22:22 \
    --label "localnet.dns.git.domain=${DNS_RECORD}" \
    --label "localnet.dns.git.answer=${LOCAL_IP_CLOUD}" \
    --label "traefik.enable=true" \
    --label "tag=app-external" \
    --label "traefik.docker.network=${CONTAINER_NETWORK_NAME}" \
    --label "traefik.http.services.${TRAEFIK_ROUTER_NAME}.loadbalancer.server.port=3000" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.service=${NAME}" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.rule=Host(\`${DNS_RECORD}\`)" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.entrypoints=https" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls=true" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
    --name "$CONTAINER_NAME" \
    "$CONTAINER_IMAGE":"$GOGS_VERSION"
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
