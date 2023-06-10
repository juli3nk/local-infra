#!/usr/bin/env bash

LOCAL_IP_HTTP="$(jq -r '.ip_addresses.http.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"
LOCAL_DATA_DIR="${HOME}/Data/traefik"

NAME="traefik"

DNS_RECORD="${NAME}.${LOCAL_DOMAIN}"

TRAEFIK_VERSION="v2.10.1"

CONTAINER_NAME="$NAME"
CONTAINER_NETWORK_EXTERNAL="external"

TRAEFIK_ROUTER_NAME="$NAME"
TRAEFIK_CERT_RESOLVER_NAME="stepca"

ACME_URL="https://ca.${LOCAL_DOMAIN}/acme/traefik/directory"
ACME_EMAIL="user@${LOCAL_DOMAIN}"


if [ ! -d "$LOCAL_DATA_DIR/acme" ]; then
	mkdir -p $LOCAL_DATA_DIR/acme
fi

test $(docker container ls --filter "name=${CONTAINER_NAME}" -q | wc -l) -eq 0 || docker container kill "${CONTAINER_NAME}"

#	--label "tag=app-external" \
#		--providers.docker.constraints="Label('tag','app-external')" \


local_ca_certs="/etc/ssl/certs/ca-certificates.crt"
# ca_certs=$(sudo ls -l /etc/static/ssl/certs/ca-certificates.crt | awk '{ print $NF }')

#		--entrypoints.http.http.redirections.entryPoint.to=https \
#		--entrypoints.http.http.redirections.entryPoint.scheme=https \

docker container run \
	-d \
	--rm \
	--mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock,ro \
	--mount type=bind,src=${local_ca_certs},dst=/etc/ssl/certs/ca-certificates.crt,ro \
	--mount type=bind,src=${LOCAL_DATA_DIR}/acme,dst=/etc/ssl/acme \
	--network "$CONTAINER_NETWORK_EXTERNAL" \
	--publish "${LOCAL_IP_HTTP}":80:80 \
	--publish "${LOCAL_IP_HTTP}":443:443 \
	--label "dns.domain=${DNS_RECORD}" \
	--label "dns.answer=${LOCAL_IP_HTTP}" \
	--label "traefik.enable=true" \
	--label "traefik.docker.network=${DOCKER_NETWORK_EXTERNAL}" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.service=api@internal" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.rule=Host(\`${DNS_RECORD}\`)" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.entrypoints=https" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls=true" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
	--name "${CONTAINER_NAME}" \
	traefik:"$TRAEFIK_VERSION" \
		--log.level=DEBUG \
		--api.dashboard=true \
		--api.insecure=true \
		--entrypoints.http.address=:80/tcp \
		--entrypoints.https.address=:443/tcp \
		--providers.docker \
		--providers.docker.network="${DOCKER_NETWORK_EXTERNAL}" \
		--providers.docker.exposedByDefault=false \
		--certificatesResolvers."${TRAEFIK_CERT_RESOLVER_NAME}".acme.caServer="${ACME_URL}" \
		--certificatesResolvers."${TRAEFIK_CERT_RESOLVER_NAME}".acme.email="${ACME_EMAIL}" \
		--certificatesResolvers."${TRAEFIK_CERT_RESOLVER_NAME}".acme.storage=/etc/ssl/acme/acme.json \
		--certificatesResolvers."${TRAEFIK_CERT_RESOLVER_NAME}".acme.tlsChallenge=true \
		--certificatesResolvers."${TRAEFIK_CERT_RESOLVER_NAME}".acme.httpChallenge=false \
		--certificatesResolvers."${TRAEFIK_CERT_RESOLVER_NAME}".acme.dnsChallenge=false \
		--certificatesResolvers."${TRAEFIK_CERT_RESOLVER_NAME}".acme.certificatesDuration=24 \
		--providers.providersThrottleDuration=100
