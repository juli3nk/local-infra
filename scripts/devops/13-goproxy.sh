#!/usr/bin/env bash
# goproxy.sh - Runs a local Go module proxy (e.g. Athens or similar)
set -euo pipefail

ACTION="${1:-}"

GOPROXY_VERSION="$(jq -r 'goproxy' ${HOME}/.config/local/versions.json)"

LOCAL_IP_CLOUD="$(jq -r '.ip_addresses.cloud.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"
LOCAL_DATA_PATH="${HOME}/Data/goproxy"

SECRETS_PATH="${HOME}/Data/secrets"

NAME="goproxy"

CONTAINER_NAME="$NAME"
CONTAINER_NETWORK_EXTERNAL="external"

DNS_RECORD="${NAME}.local"

TRAEFIK_ROUTER_NAME="$NAME"

start() {
  mkdir -p "$LOCAL_DATA_PATH"

  test $(docker container ls --filter "name=${CONTAINER_NAME}" -q | wc -l) -eq 0 || docker container kill "$CONTAINER_NAME"

  docker container run \
    -d \
    --rm \
    --mount type=bind,src="${LOCAL_DATA_PATH}",dst=/go \
    --mount type=bind,src="${SECRETS_PATH}/netrc",dst=/root/.netrc,ro \
    --network "$CONTAINER_NETWORK_NAME" \
    --env "GO111MODULE=on" \
    --env "GOSUMDB=off" \
    --label "localnet.dns.goproxy.domain=${DNS_RECORD}" \
    --label "localnet.dns.goproxy.answer=${LOCAL_IP_CLOUD}" \
    --label "traefik.enable=true" \
    --label "tag=app-external" \
    --label "traefik.docker.network=${CONTAINER_NETWORK_NAME}" \
    --label "traefik.http.services.${TRAEFIK_ROUTER_NAME}.loadbalancer.server.port=80" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.service=${NAME}" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.rule=Host(\`${DNS_RECORD}\`)" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.entrypoints=http" \
    --name "$CONTAINER_NAME" \
    docker.io/goproxy/goproxy:"$GOPROXY_VERSION" \
      -listen=0.0.0.0:80
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
