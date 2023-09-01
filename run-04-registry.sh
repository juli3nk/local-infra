#!/usr/bin/env bash
set -o errexit

LOCAL_IP_HTTP="$(jq -r '.ip_addresses.http.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"
LOCAL_DATA_PATH="${HOME}/Data/registry"

NAME_REGISTRY="registry"
NAME_UI="registry-ui"

DNS_RECORD_REGISTRY="${NAME_REGISTRY}.${LOCAL_DOMAIN}"
DNS_RECORD_UI="${NAME_UI}.${LOCAL_DOMAIN}"

IMAGE_NAME_REGISTRY="docker.io/registry"
IMAGE_TAG_REGISTRY="2"
IMAGE_NAME_UI="docker.io/joxit/docker-registry-ui"
IMAGE_TAG_UI="main"

TRAEFIK_ROUTER_NAME_REGISTRY="$NAME_REGISTRY"
TRAEFIK_ROUTER_NAME_UI="$NAME_UI"

TRAEFIK_CERT_RESOLVER_NAME="stepca"


# Registry
if [ "$(docker container inspect -f '{{ .State.Running }}' "$NAME_REGISTRY" 2> /dev/null || true)" != 'true' ]; then
	mkdir -p "$LOCAL_DATA_PATH"

	docker container run \
		-d \
		--rm \
		--mount type=bind,src="${LOCAL_DATA_PATH}",dst=/var/lib/registry \
		--net external \
		--env "REGISTRY_HTTP_HEADERS_Access-Control-Origin=[https://${DNS_RECORD_UI}]" \
		--env "REGISTRY_HTTP_HEADERS_Access-Control-Allow-Methods=[HEAD,GET,OPTIONS,DELETE]" \
		--env "REGISTRY_HTTP_HEADERS_Access-Control-Credentials=[true]" \
		--env "REGISTRY_HTTP_HEADERS_Access-Control-Allow-Headers=[Authorization,Accept,Cache-Control]" \
		--env "REGISTRY_HTTP_HEADERS_Access-Control-Expose-Headers=[Docker-Content-Digest]" \
		--env "REGISTRY_STORAGE_DELETE_ENABLED=true" \
		--label "dns.domain=${DNS_RECORD_REGISTRY}" \
		--label "dns.answer=${LOCAL_IP_HTTP}" \
		--label "traefik.enable=true" \
		--label "tag=app-external" \
		--label "traefik.docker.network=external" \
		--label "traefik.http.services.${TRAEFIK_ROUTER_NAME_REGISTRY}.loadbalancer.server.port=5000" \
		--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_REGISTRY}.service=${NAME_REGISTRY}" \
		--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_REGISTRY}.rule=Host(\`${DNS_RECORD_REGISTRY}\`)" \
		--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_REGISTRY}.entrypoints=https" \
		--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_REGISTRY}.tls=true" \
		--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_REGISTRY}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
		--name "$NAME_REGISTRY" \
		"${IMAGE_NAME_REGISTRY}:${IMAGE_TAG_REGISTRY}"
fi
exit


# UI
if [ "$(docker container inspect -f '{{ .State.Running }}' "$NAME_UI" 2> /dev/null || true)" == 'true' ]; then
	exit 1
fi

docker container run \
	-d \
	--rm \
	--net external \
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
	--label "dns.domain=${DNS_RECORD_UI}" \
	--label "dns.answer=${LOCAL_IP_HTTP}" \
	--label "traefik.enable=true" \
	--label "tag=app-external" \
	--label "traefik.docker.network=external" \
	--label "traefik.http.services.${TRAEFIK_ROUTER_NAME_UI}.loadbalancer.server.port=80" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_UI}.service=${NAME_UI}" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_UI}.rule=Host(\`${DNS_RECORD_UI}\`)" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_UI}.entrypoints=https" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_UI}.tls=true" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME_UI}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
	--name "$NAME_UI" \
	"${IMAGE_NAME_UI}:${IMAGE_TAG_UI}"
