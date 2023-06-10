#!/usr/bin/env bash

LOCAL_DATA_DIR="${HOME}/Data/step-ca"
CONTAINER_STEP_HOME_DIR="/home/step"


docker container run \
    -ti \
    --rm \
    --mount type=bind,src=${LOCAL_DATA_DIR},dst=${CONTAINER_STEP_HOME_DIR} \
    docker.io/smallstep/step-ca \
        vi /home/step/secrets/password