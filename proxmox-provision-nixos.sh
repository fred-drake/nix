#!/usr/bin/env bash

PROXMOX_SERVER=baine
HOSTNAME=kavita
CONTAINER_ID=119
STORAGE=local-lvm
MEMORY=4096
DISK_SIZE_IN_GB=100
UNPRIVILEGED=1

ssh $PROXMOX_SERVER "pct create $CONTAINER_ID \
    --arch amd64 local:vztmpl/nixos-system-x86_64-linux.tar.xz \
    --ostype unmanaged \
    --description nixos \
    --hostname $HOSTNAME \
    --net0 name=eth0,bridge=vmbr3,ip=dhcp,firewall=1 \
    --storage $STORAGE \
    --memory 4096 \
    --rootfs $STORAGE:$DISK_SIZE_IN_GB \
    --unprivileged $UNPRIVILEGED \
    --features nesting=1 \
    --cmode console \
    --onboot 1 \
    --start 1"
