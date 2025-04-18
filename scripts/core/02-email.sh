#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"

SMTP4DEV_VERSION="$(jq -r '.smtp4dev' ${HOME}/.config/local/versions.json)"

LOCAL_IP_CLOUD="$(jq -r '.ip_addresses.cloud.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"

CONTAINER_IMAGE="docker.io/rnwood/smtp4dev"
CONTAINER_NAME="mail"
CONTAINER_NETWORK_EXTERNAL="external"

DNS_RECORD_SMTP="smtp.${LOCAL_DOMAIN}"
DNS_RECORD_IMAP="imap.${LOCAL_DOMAIN}"
DNS_RECORD_WEBMAIL="webmail.${LOCAL_DOMAIN}"

TRAEFIK_ROUTER_NAME="webmail"
TRAEFIK_CERT_RESOLVER_NAME="stepca"

start() {
  docker container run \
    -d \
    --rm \
    --network "$CONTAINER_NETWORK_EXTERNAL" \
    --publish "${LOCAL_IP_CLOUD}":25:25 \
    --publish "${LOCAL_IP_CLOUD}":143:143 \
    --env "ServerOptions__DisableIPv6=true" \
    --env "ServerOptions__Urls=http://*:80" \
    --env "ServerOptions__HostName=${DNS_RECORD_SMTP}" \
    --label "localnet.dns.smtp.domain=${DNS_RECORD_SMTP}" \
    --label "localnet.dns.smtp.answer=${LOCAL_IP_CLOUD}" \
    --label "localnet.dns.imap.domain=${DNS_RECORD_IMAP}" \
    --label "localnet.dns.imap.answer=${LOCAL_IP_CLOUD}" \
    --label "localnet.dns.webmail.domain=${DNS_RECORD_WEBMAIL}" \
    --label "localnet.dns.webmail.answer=${LOCAL_IP_CLOUD}" \
    --label "traefik.enable=true" \
    --label "tag=app-external" \
    --label "traefik.docker.network=${CONTAINER_NETWORK_EXTERNAL}" \
    --label "traefik.http.services.${TRAEFIK_ROUTER_NAME}.loadbalancer.server.port=80" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.service=webmail" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.rule=Host(\`${DNS_RECORD_WEBMAIL}\`)" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.entrypoints=https" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls=true" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
    --name "$CONTAINER_NAME" \
    "$CONTAINER_IMAGE":"$SMTP4DEV_VERSION"
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