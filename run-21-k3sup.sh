#!/usr/bin/env bash

HOST="dev-d11-infradockerlab-01"
#HOST="uni-lab"
USERNAME="jkassar"
CONTEXT_NAME="outscale-lab-1"

k3sup install \
    --host "$HOST" \
    --user "$USERNAME" \
    --sudo \
    --local-path "${HOME}/.kubeconfig.d/${CONTEXT_NAME}.yaml" \
    --context "${CONTEXT_NAME}" \
    --k3s-extra-args="--data-dir /srv/k3s"
#    --k3s-extra-args '--disable traefik'
