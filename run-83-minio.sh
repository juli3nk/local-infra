#!/usr/bin/env bash

LOCAL_IP_HTTP="$(jq -r '.ip_addresses.http.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"
LOCAL_DATA_PATH="${HOME}/Data/minio"

NAME="minio"
CONSOLE_NAME="console"

DNS_RECORD="${NAME}.${LOCAL_DOMAIN}"
DNS_RECORD_CONSOLE="${CONSOLE_NAME}.${NAME}.${LOCAL_DOMAIN}"

CONTAINER_NAME="$NAME"

TRAEFIK_ROUTER_NAME="$NAME"
TRAEFIK_ROUTER_CONSOLE_NAME="$CONSOLE_NAME"
TRAEFIK_CERT_RESOLVER_NAME="stepca"


mkdir -p "$LOCAL_DATA_PATH"

docker container run \
	-d \
	--rm \
	--mount type=bind,src="${LOCAL_DATA_PATH}",dst=/data \
	--net external \
	--label "dns.domain=${DNS_RECORD}" \
	--label "dns.answer=${LOCAL_IP_HTTP}" \
	--label "traefik.enable=true" \
	--label "tag=app-external" \
	--label "traefik.docker.network=external" \
	--label "traefik.http.services.${TRAEFIK_ROUTER_NAME}.loadbalancer.server.port=9000" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.service=${NAME}" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.rule=Host(\`${DNS_RECORD}\`)" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.entrypoints=https" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls=true" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
	--label "traefik.http.services.${TRAEFIK_ROUTER_CONSOLE_NAME}.loadbalancer.server.port=9001" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_CONSOLE_NAME}.service=${CONSOLE_NAME}" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_CONSOLE_NAME}.rule=Host(\`${DNS_RECORD_CONSOLE}\`)" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_CONSOLE_NAME}.entrypoints=https" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_CONSOLE_NAME}.tls=true" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_CONSOLE_NAME}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
	--name "$CONTAINER_NAME" \
    quay.io/minio/minio \
        server \
        /data \
        --console-address ":9001"
