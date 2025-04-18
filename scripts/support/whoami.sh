#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"

WHOAMI_VERSION="latest"

LOCAL_IP_HTTP="$(jq -r '.ip_addresses.cloud.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"

NAME="whoami"

CONTAINER_IMAGE="docker.io/traefik/whoami"
CONTAINER_NAME="$NAME"

TRAEFIK_ROUTER_NAME="$NAME"
TRAEFIK_CERT_RESOLVER_NAME="stepca"
TRAEFIK_DNS_RECORD="${NAME}.${LOCAL_DOMAIN}"


docker container run \
	-d \
	--rm \
	--network external \
	--label "dns.domain=${TRAEFIK_DNS_RECORD}" \
	--label "dns.answer=${LOCAL_IP_HTTP}" \
	--label "traefik.enable=true" \
	--label "tag=app-external" \
	--label "traefik.docker.network=external" \
	--label "traefik.http.services.${TRAEFIK_ROUTER_NAME}.loadbalancer.server.port=80" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.service=${NAME}" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.rule=Host(\`${TRAEFIK_DNS_RECORD}\`)" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.entrypoints=https" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls=true" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
	--name "$CONTAINER_NAME" \
	"$CONTAINER_IMAGE":"$WHOAMI_VERSION"
