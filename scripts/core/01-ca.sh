#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"

STEP_CA_VERSION="$(jq -r '.step_ca' ${HOME}/.config/local/versions.json)"

LOCAL_IP_CA="$(jq -r '.ip_addresses.ca.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"
LOCAL_DATA_DIR="${HOME}/Data/step-ca"

NAME="step-ca"

CONTAINER_IMAGE="docker.io/smallstep/step-ca"
CONTAINER_NAME="$NAME"
CONTAINER_NETWORK_EXTERNAL="external"
CONTAINER_STEP_HOME_DIR="/home/step"

DNS_RECORD="ca.${LOCAL_DOMAIN}"


init() {
	mkdir -p "$LOCAL_DATA_DIR"

  if [ $(ls -1 "${LOCAL_DATA_DIR}/" | wc -l) -gt 0 ]; then
    echo -e "CA is already initialized"
    exit 1
  fi

  docker container run \
    -ti \
    --rm \
    --mount type=bind,src=${LOCAL_DATA_DIR},dst=${CONTAINER_STEP_HOME_DIR} \
    "$CONTAINER_IMAGE":"$STEP_CA_VERSION" \
      step ca init
}

password() {
  docker container run \
    -ti \
    --rm \
    --mount type=bind,src=${LOCAL_DATA_DIR},dst=${CONTAINER_STEP_HOME_DIR} \
    "$CONTAINER_IMAGE":"$STEP_CA_VERSION" \
      vi /home/step/secrets/password
}

bootstrap() {
  if [ -z "$1" ]; then
    echo -e "you must provide CA URL"
    exit 1
  fi
  if [ -z "$2" ]; then
    echo -e "you must provide CA fingerprint"
    exit 1
  fi

  step \
    ca \
    bootstrap \
    --ca-url "$1" \
    --fingerprint "$2"
}

acme() {
  if [ -z "$1" ]; then
    echo -e "you must provide a name for the ACME provisioner"
    exit 1
  fi

  docker container exec -ti step-ca \
    step \
      ca \
      provisioner \
      add "$1" \
      --type ACME
}

start() {
  if [ ! -d "$LOCAL_DATA_DIR" ]; then
    init
  fi

  if [ $(ls -1 "${LOCAL_DATA_DIR}/" | wc -l) -eq 0 ]; then
    init
  fi

  docker container run \
    -d \
    --rm \
    --mount type=bind,src="${LOCAL_DATA_DIR}",dst="${CONTAINER_STEP_HOME_DIR}" \
    --network "$CONTAINER_NETWORK_EXTERNAL" \
    --publish "${LOCAL_IP_CA}":443:443 \
    --label "localnet.dns.ca.domain=${DNS_RECORD}" \
    --label "localnet.dns.ca.answer=${LOCAL_IP_CA}" \
    --name "$CONTAINER_NAME" \
    "$CONTAINER_IMAGE":"$STEP_CA_VERSION"
}

stop() {
  docker container stop "$CONTAINER_NAME"
}

function usage() {
  echo "Usage: $0 {init|password|bootstrap|acme|start|stop}"
  exit 1
}

case "$ACTION" in
  init)       init ;;
  password)   password ;;
  bootstrap)  bootstrap ;;
  acme)       acme ;;
  start)      start ;;
  stop)       stop ;;
  *)          usage ;;
esac