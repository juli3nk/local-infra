#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"

VM_NAME="k3s"

if [ "$(virsh list --all | grep -c "$VM_NAME")" -eq 0 ]; then
    virt-install \
        --virt-type kvm \
        --name "$VM_NAME" \
        --location http://deb.debian.org/debian/dists/bullseye/main/installer-amd64/ \
        --os-variant debian11 \
        --disk size=80 \
        --memory 4096 \
        --graphics none \
        --console pty,target_type=serial \
        --extra-args "console=ttyS0"
else
    if [ "$(virsh list --state-running | grep -c "$VM_NAME")" -gt 0 ]; then
        exit 0
    fi

    virsh start "$VM_NAME"
fi

