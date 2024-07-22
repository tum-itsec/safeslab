#!/bin/bash

source "$(dirname "${0}")"/common.sh

KERNEL="$1"
INITRD="$2"

qemu-system-x86_64 \
          -kernel "${KERNEL}" \
          -initrd "${INITRD}" \
          -drive file="${ROOTFS_IMG}",index=0,media=disk,format=raw \
          -nographic \
          -append "root=/dev/sda clearcpuid=58 rw console=ttyS0 nokaslr net.ifnames=0" \
	  -m "${VM_RAM_GB}G" \
          -smp 16 \
          --enable-kvm \
          -device e1000,netdev=net0 \
          -netdev user,id=net0,hostfwd=tcp:127.0.0.1:${VMPORT}-:22 \
          -cpu host \
