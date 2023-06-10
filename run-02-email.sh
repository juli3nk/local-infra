#!/usr/bin/env bash

LOCAL_IP_SMTP="$(jq -r '.ip_addresses.http.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DOMAIN="$(jq -r '.domain' ${HOME}/.config/local/net.json)"

NAME="smtp"

DNS_RECORD_SMTP="${NAME}.${LOCAL_DOMAIN}"
DNS_RECORD_WEBMAIL="webmail.${LOCAL_DOMAIN}"

CONTAINER_NAME="$NAME"

TRAEFIK_ROUTER_NAME="webmail"
TRAEFIK_CERT_RESOLVER_NAME="stepca"


docker container run \
	-d \
	--rm \
	--net external \
	--publish "${LOCAL_IP_SMTP}":25:25 \
	--label "dns.domain=${DNS_RECORD_SMTP}" \
	--label "dns.answer=${LOCAL_IP_SMTP}" \
	--label "dns.domain=${DNS_RECORD_WEBMAIL}" \
	--label "dns.answer=${LOCAL_IP_SMTP}" \
	--label "traefik.enable=true" \
	--label "tag=app-external" \
	--label "traefik.docker.network=external" \
	--label "traefik.http.services.${TRAEFIK_ROUTER_NAME}.loadbalancer.server.port=80" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.service=webmail" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.rule=Host(\`${DNS_RECORD_WEBMAIL}\`)" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.entrypoints=https" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls=true" \
	--label "traefik.http.routers.${TRAEFIK_ROUTER_NAME}.tls.certResolver=${TRAEFIK_CERT_RESOLVER_NAME}" \
	--name "$CONTAINER_NAME" \
	docker.io/rnwood/smtp4dev