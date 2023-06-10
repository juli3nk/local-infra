#!/usr/bin/env bash

if ! source ./env-main.sh; then exit 1 ; fi

LOCAL_IP_SMTP="$(jq -r '.ip_addresses.kind.ip_address' ${HOME}/.config/local/net.json)"

NAME="smtp"

DNS_RECORD_SMTP="${NAME}.${LOCAL_DOMAIN}"
DNS_RECORD_WEBMAIL="webmail.${LOCAL_DOMAIN}"

CONTAINER_NAME="$NAME"


docker container run \
    -d \
    --rm \
    -p "${LOCAL_IP_SMTP}":80:80 \
    -p "${LOCAL_IP_SMTP}":25:25 \
    --label "dns.domain=${DNS_RECORD_SMTP}" \
	--label "dns.answer=${LOCAL_IP_SMTP}" \
    --label "dns.domain=${DNS_RECORD_WEBMAIL}" \
	--label "dns.answer=${LOCAL_IP_SMTP}" \
    --name "$CONTAINER_NAME" \
    docker.io/rnwood/smtp4dev