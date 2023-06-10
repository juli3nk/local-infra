#!/usr/bin/env bash

LOCAL_DATA_DIR="${HOME}/Data/step-ca"

CONTAINER_STEP_HOME_DIR="/home/step"


if [ ! -d "$LOCAL_DATA_DIR" ]; then
	mkdir -p "$LOCAL_DATA_DIR"
fi

if [ $(ls -1 "${LOCAL_DATA_DIR}/" | wc -l) -gt 0 ]; then
	echo -e "CA is already initialized"
	exit 1
fi

docker container run \
	-ti \
	--rm \
	--mount type=bind,src=${LOCAL_DATA_DIR},dst=${CONTAINER_STEP_HOME_DIR} \
	docker.io/smallstep/step-ca \
		step ca init
