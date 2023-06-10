#!/usr/bin/env bash

LOCAL_IP_HTTP="$(jq -r '.ip_addresses.http.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"
LOCAL_DATA_PATH="${HOME}/Data/goproxy"

SECRETS_PATH="${HOME}/Data/secrets"

NAME="goproxy"

DNS_RECORD="${NAME}.local"

CONTAINER_NAME="$NAME"

TRAEFIK_ROUTER_NAME="$NAME"


mkdir -p "$LOCAL_DATA_PATH"

test $(docker container ls --filter "name=${CONTAINER_NAME}" -q | wc -l) -eq 0 || docker container kill "${CONTAINER_NAME}"

docker container run \
	-d \
	--rm \
	--mount type=bind,src="${LOCAL_DATA_PATH}",dst=/go \
	--mount type=bind,src="${SECRETS_PATH}/netrc",dst=/root/.netrc,ro \
	--net external \
	--env "GO111MODULE=on" \
	--env "GOSUMDB=off" \
	--label "dns.domain=${DNS_RECORD}" \
	--label "dns.answer=${LOCAL_IP_HTTP}" \
	--label "traefik.enable=true" \
	--label "tag=app-external" \
	--label "traefik.docker.network=external" \
	--label "traefik.http.services.${TRAEFIK_ROUTER_NAME}.loadbalancer.server.port=80" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.service=${NAME}" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.rule=Host(\`${DNS_RECORD}\`)" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.entrypoints=http" \
	--name "$CONTAINER_NAME" \
	docker.io/goproxy/goproxy \
		-listen=0.0.0.0:80
