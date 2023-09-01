#!/usr/bin/env bash

#helm repo add longhorn https://charts.longhorn.io
helm install longhorn longhorn/longhorn \
    --create-namespace \
    --namespace longhorn-system \
    --version 1.4.2 \
    --set persistence.defaultClassReplicaCount=1
