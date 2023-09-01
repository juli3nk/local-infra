#!/usr/bin/env bash
set -e

DAGGER_VERSION="0.6.4"
CONTAINER_NAME="dagger-runner"


docker container run \
    -d \
    --restart always \
    --privileged \
    --mount type=volume,src=dagger-engine,dst=/var/lib/dagger \
    --mount type=bind,src=/etc/ssl/certs,dst=/etc/ssl/certs,ro \
    --name "$CONTAINER_NAME" \
    registry.dagger.io/engine:v${DAGGER_VERSION}

echo -e "\n\nExport variable:\n\n_EXPERIMENTAL_DAGGER_RUNNER_HOST=docker-container://${CONTAINER_NAME}\n"
