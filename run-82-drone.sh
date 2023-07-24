#!/usr/bin/env bash

LOCAL_IP_HTTP="$(jq -r '.ip_addresses.http.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"
LOCAL_DATA_PATH="${HOME}/Data/drone"

NAME="ci"

DNS_RECORD="${NAME}.${LOCAL_DOMAIN}"

CONTAINER_NAME="$NAME"

TRAEFIK_ROUTER_NAME="$NAME"
TRAEFIK_CERT_RESOLVER_NAME="stepca"

DRONE_RPC_SECRET="super-duper-secret"

mkdir -p "$LOCAL_DATA_PATH"

local_ca_certs="/etc/ssl/certs/ca-certificates.crt"

docker container run \
	-d \
	--rm \
	--mount type=bind,src=${local_ca_certs},dst=/etc/ssl/certs/ca-certificates.crt,ro \
	--mount type=bind,src="${LOCAL_DATA_PATH}",dst=/data \
    --env "DRONE_AGENTS_ENABLED=true" \
    --env "DRONE_GOGS_SERVER=https://git.${LOCAL_DOMAIN}" \
    --env "DRONE_RPC_SECRET=${DRONE_RPC_SECRET}" \
    --env "DRONE_SERVER_PROTO=http" \
    --env "DRONE_SERVER_HOST=${DNS_RECORD}" \
	--net external \
	--label "dns.domain=${DNS_RECORD}" \
	--label "dns.answer=${LOCAL_IP_HTTP}" \
	--label "traefik.enable=true" \
	--label "tag=app-external" \
	--label "traefik.docker.network=external" \
	--label "traefik.http.services.${TRAEFIK_ROUTER_NAME}.loadbalancer.server.port=80" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.service=${NAME}" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.rule=Host(\`${DNS_RECORD}\`)" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.entrypoints=https" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls=true" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
	--name "$CONTAINER_NAME" \
	docker.io/drone/drone:2

#    --publish=3000:3000 \
docker container run \
	-d \
	--rm \
	--mount type=bind,src=${local_ca_certs},dst=/etc/ssl/certs/ca-certificates.crt,ro \
	--mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
    --env "DRONE_RPC_PROTO=https" \
    --env "DRONE_RPC_HOST=${DNS_RECORD}" \
    --env "DRONE_RPC_SECRET=${DRONE_RPC_SECRET}" \
    --env "DRONE_RUNNER_CAPACITY=2" \
    --env "DRONE_RUNNER_NAME=runner-1" \
    --name "${CONTAINER_NAME}-runner" \
    docker.io/drone/drone-runner-docker:1
