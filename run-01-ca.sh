#!/usr/bin/env bash

LOCAL_IP_CA="$(jq -r '.ip_addresses.ca.ip_address' ${HOME}/.config/local/net.json)"
LOCAL_DATA_DIR="${HOME}/Data/step-ca"

NAME="step-ca"

DNS_RECORD="${NAME}.${LOCAL_DOMAIN}"

CONTAINER_NAME="$NAME"
CONTAINER_STEP_HOME_DIR="/home/step"

NETWORK_NAME="external"


if [ ! -d "$LOCAL_DATA_DIR" ]; then
	echo -e "you must initialize CA first"
	exit 1
fi

if [ $(ls -1 "${LOCAL_DATA_DIR}/" | wc -l) -eq 0 ]; then
	echo -e "you must initialize CA first"
	exit 1
fi

docker container run \
	-d \
	--rm \
	--mount type=bind,src="${LOCAL_DATA_DIR}",dst="${CONTAINER_STEP_HOME_DIR}" \
	--network "$NETWORK_NAME" \
	-p "${LOCAL_IP_CA}":8443:443 \
	--label "dns.domain=${DNS_RECORD}" \
	--label "dns.answer=${LOCAL_IP_CA}" \
	--name "$CONTAINER_NAME" \
	docker.io/smallstep/step-ca
