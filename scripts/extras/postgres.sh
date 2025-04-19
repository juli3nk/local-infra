#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"

POSTGRES_VERSION="$(jq -r '.postgres' ${HOME}/.config/local/versions.json)"

LOCAL_IP_CLOUD="$(jq -r '.ip_addresses.cloud.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"
LOCAL_DATA_DIR="${HOME}/Data/postgres"

NAME="postgres"

CONTAINER_NAME="$NAME"
CONTAINER_NETWORK_DATABASE="database"
CONTAINER_SECRET_POSTGRES="/run/secrets/postgres"

DNS_RECORD="pg.${LOCAL_DOMAIN}"

POSTGRES_PASSWORD_FILE="${POSTGRES_PASSWORD_FILE:-${HOME}/Data/Secrets/postgres}"

network-create() {
  test $(docker network ls --filter "name=${CONTAINER_NETWORK_DATABASE}" -q | wc -l) -eq 1 && return

  docker network create \
    --driver bridge \
    --attachable \
    "$CONTAINER_NETWORK_DATABASE"
}

start() {
  network-create

  mkdir -p "$LOCAL_DATA_DIR"

  if [ ! -f "$POSTGRES_PASSWORD_FILE" ]; then
    mkdir -p "$(dirname "$POSTGRES_PASSWORD_FILE")"
    echo "admin01%" > "$POSTGRES_PASSWORD_FILE"
  fi

  docker container run \
    -d \
    --rm \
    --mount type=bind,src="$LOCAL_DATA_DIR",dst=/var/lib/postgresql/data \
    --mount type=bind,src="$POSTGRES_PASSWORD_FILE",dst="$CONTAINER_SECRET_POSTGRES" \
    --network "$CONTAINER_NETWORK_DATABASE" \
    --env POSTGRES_PASSWORD_FILE="$CONTAINER_SECRET_POSTGRES" \
    --name "$CONTAINER_NAME" \
    postgres:"$POSTGRES_VERSION"
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
