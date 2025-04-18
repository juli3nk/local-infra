#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"

TRAEFIK_VERSION="$(jq -r '.traefik' ${HOME}/.config/local/versions.json)"

LOCAL_IP_CLOUD="$(jq -r '.ip_addresses.cloud.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"
LOCAL_DATA_DIR="${HOME}/Data/traefik"
LOCAL_CA_CERTS="/etc/ssl/certs/ca-certificates.crt"

NAME="traefik"

CONTAINER_IMAGE="docker.io/traefik"
CONTAINER_NAME="$NAME"
CONTAINER_NETWORK_EXTERNAL="external"

DNS_RECORD="${NAME}.${LOCAL_DOMAIN}"

TRAEFIK_ROUTER_NAME="$NAME"
TRAEFIK_CERT_RESOLVER_NAME="stepca"

ACME_URL="https://ca.${LOCAL_DOMAIN}/acme/traefik/directory"
ACME_EMAIL="user@${LOCAL_DOMAIN}"

start() {
  mkdir -p $LOCAL_DATA_DIR/acme

  docker container run \
    -d \
    --rm \
    --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock,ro \
    --mount type=bind,src=${LOCAL_CA_CERTS},dst=/etc/ssl/certs/ca-certificates.crt,ro \
    --mount type=bind,src=${LOCAL_DATA_DIR}/acme,dst=/etc/ssl/acme \
    --network "$CONTAINER_NETWORK_EXTERNAL" \
    --publish "${LOCAL_IP_CLOUD}":80:80 \
    --publish "${LOCAL_IP_CLOUD}":443:443 \
    --label "localnet.dns.traefik.domain=${DNS_RECORD}" \
    --label "localnet.dns.traefik.answer=${LOCAL_IP_CLOUD}" \
    --label "traefik.enable=true" \
    --label "traefik.docker.network=${CONTAINER_NETWORK_EXTERNAL}" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.service=api@internal" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.rule=Host(\`${DNS_RECORD}\`)" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.entrypoints=https" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls=true" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
    --name "${CONTAINER_NAME}" \
    "$CONTAINER_IMAGE":"$TRAEFIK_VERSION" \
      --log.level=DEBUG \
      --api.dashboard=true \
      --api.insecure=true \
      --entrypoints.http.address=:80/tcp \
      --entrypoints.https.address=:443/tcp \
      --providers.docker \
      --providers.docker.network="${CONTAINER_NETWORK_EXTERNAL}" \
      --providers.docker.exposedByDefault=false \
      --certificatesResolvers."${TRAEFIK_CERT_RESOLVER_NAME}".acme.caServer="${ACME_URL}" \
      --certificatesResolvers."${TRAEFIK_CERT_RESOLVER_NAME}".acme.email="${ACME_EMAIL}" \
      --certificatesResolvers."${TRAEFIK_CERT_RESOLVER_NAME}".acme.storage=/etc/ssl/acme/acme.json \
      --certificatesResolvers."${TRAEFIK_CERT_RESOLVER_NAME}".acme.tlsChallenge=true \
      --certificatesResolvers."${TRAEFIK_CERT_RESOLVER_NAME}".acme.httpChallenge=false \
      --certificatesResolvers."${TRAEFIK_CERT_RESOLVER_NAME}".acme.dnsChallenge=false \
      --certificatesResolvers."${TRAEFIK_CERT_RESOLVER_NAME}".acme.certificatesDuration=24 \
      --providers.providersThrottleDuration=100
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
