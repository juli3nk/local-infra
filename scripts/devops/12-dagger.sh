#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"

DAGGER_VERSION="$(jq -r '.dagger' ${HOME}/.config/local/versions.json)"

CONTAINER_IMAGE="registry.dagger.io/engine"
CONTAINER_NAME="dagger-engine"

start() {
  docker container run \
    -d \
    --restart always \
    --privileged \
    --mount type=volume,src=dagger-engine,dst=/var/lib/dagger \
    --mount type=bind,src=/etc/ssl/certs,dst=/etc/ssl/certs,ro \
    --name "$CONTAINER_NAME" \
    "$CONTAINER_IMAGE":"$DAGGER_VERSION"

  echo -e "\n\nExport variable:\n\n_EXPERIMENTAL_DAGGER_RUNNER_HOST=docker-container://${CONTAINER_NAME}\n"
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
