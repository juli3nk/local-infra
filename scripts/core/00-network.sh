#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"

CONTAINER_NETWORK_EXTERNAL="external"

start() {
  test $(docker network ls --filter "name=${CONTAINER_NETWORK_EXTERNAL}" -q | wc -l) -eq 1 && exit 0

  docker network create \
    --driver bridge \
    --attachable \
    "$CONTAINER_NETWORK_EXTERNAL"
}

stop() {
  exit 0
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