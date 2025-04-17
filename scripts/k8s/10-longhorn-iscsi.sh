#!/usr/bin/env bash

kubectl create ns longhorn-system
kubectl -n longhorn-system apply -f config/longhorn/longhorn-iscsi-installation.yaml
