#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"

REGISTRY_VERSION="$(jq -r 'registry' ${HOME}/.config/local/versions.json)"
REGISTRY_UI_VERSION="$(jq -r 'registry-ui' ${HOME}/.config/local/versions.json)"

LOCAL_IP_CLOUD="$(jq -r '.ip_addresses.cloud.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"
LOCAL_DATA_PATH="${HOME}/Data/registry"

NAME_REGISTRY="registry"
NAME_UI="registry-ui"

CONTAINER_NAME_REGISTRY="$NAME_REGISTRY"
CONTAINER_NAME_UI="$NAME_UI"
CONTAINER_NETWORK_EXTERNAL="external"

DNS_RECORD_REGISTRY="${NAME_REGISTRY}.${LOCAL_DOMAIN}"
DNS_RECORD_UI="${NAME_UI}.${LOCAL_DOMAIN}"

TRAEFIK_ROUTER_NAME_REGISTRY="$NAME_REGISTRY"
TRAEFIK_ROUTER_NAME_UI="$NAME_UI"

TRAEFIK_CERT_RESOLVER_NAME="stepca"

# Registry
start_registry() {
	mkdir -p "$LOCAL_DATA_PATH"

	docker container run \
		-d \
		--rm \
		--mount type=bind,src="$LOCAL_DATA_PATH",dst=/var/lib/registry \
		--network "$CONTAINER_NETWORK_NAME" \
		--env "REGISTRY_HTTP_HEADERS_Access-Control-Origin=[https://${DNS_RECORD_UI}]" \
		--env "REGISTRY_HTTP_HEADERS_Access-Control-Allow-Methods=[HEAD,GET,OPTIONS,DELETE]" \
		--env "REGISTRY_HTTP_HEADERS_Access-Control-Credentials=[true]" \
		--env "REGISTRY_HTTP_HEADERS_Access-Control-Allow-Headers=[Authorization,Accept,Cache-Control]" \
		--env "REGISTRY_HTTP_HEADERS_Access-Control-Expose-Headers=[Docker-Content-Digest]" \
		--env "REGISTRY_STORAGE_DELETE_ENABLED=true" \
		--label "localnet.dns.registry.domain=${DNS_RECORD_REGISTRY}" \
		--label "localnet.dns.registry.answer=${LOCAL_IP_CLOUD}" \
		--label "traefik.enable=true" \
		--label "tag=app-external" \
		--label "traefik.docker.network=${CONTAINER_NETWORK_NAME}" \
		--label "traefik.http.services.${TRAEFIK_ROUTER_NAME_REGISTRY}.loadbalancer.server.port=5000" \
		--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_REGISTRY}.service=${NAME_REGISTRY}" \
		--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_REGISTRY}.rule=Host(\`${DNS_RECORD_REGISTRY}\`)" \
		--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_REGISTRY}.entrypoints=https" \
		--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_REGISTRY}.tls=true" \
		--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_REGISTRY}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
		--name "$CONTAINER_NAME_REGISTRY" \
		docker.io/registry:"$REGISTRY_VERSION"
}

# UI
start_ui() {
  docker container run \
    -d \
    --rm \
    --network "$CONTAINER_NETWORK_NAME" \
    --env "REGISTRY_TITLE=My Private Docker Registry" \
    --env "REGISTRY_URL=https://${DNS_RECORD_REGISTRY}" \
    --env "NGINX_PROXY_PASS_URL=http://registry:5000" \
    --env "SINGLE_REGISTRY=true" \
    --env "DELETE_IMAGES=true" \
    --env "SHOW_CONTENT_DIGEST=true" \
    --env "SHOW_CATALOG_NB_TAGS=true" \
    --env "CATALOG_MIN_BRANCHES=1" \
    --env "CATALOG_MAX_BRANCHES=1" \
    --env "TAGLIST_PAGE_SIZE=100" \
    --env "REGISTRY_SECURED=false" \
    --env "CATALOG_ELEMENTS_LIMIT=1000" \
    --label "localnet.dns.registry-ui.domain=${DNS_RECORD_UI}" \
    --label "localnet.dns.registry-ui.answer=${LOCAL_IP_CLOUD}" \
    --label "traefik.enable=true" \
    --label "tag=app-external" \
    --label "traefik.docker.network=${CONTAINER_NETWORK_NAME}" \
    --label "traefik.http.services.${TRAEFIK_ROUTER_NAME_UI}.loadbalancer.server.port=80" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_UI}.service=${NAME_UI}" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_UI}.rule=Host(\`${DNS_RECORD_UI}\`)" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_UI}.entrypoints=https" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_UI}.tls=true" \
    --label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_UI}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
    --name "$CONTAINER_NAME_UI" \
    docker.io/joxit/docker-registry-ui:"$REGISTRY_UI_VERSION"
}

start() {
  start_registry
  start_ui
}

stop() {
  docker container stop "$CONTAINER_NAME_REGISTRY"
  docker container stop "$CONTAINER_NAME_UI"
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