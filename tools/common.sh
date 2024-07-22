#!/bin/bash

# directory paths
ROOT_DIR=${ROOT_DIR:-"$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)/.."}
export ROOT_DIR
VM_ROOT_DIR="/root"
export VM_ROOT_DIR 
BUILD_DIR="${ROOT_DIR}/build"
export BUILD_DIR
RESULTS_DIR="${ROOT_DIR}/results"
export RESULTS_DIR
CONFIG_DIR="${ROOT_DIR}/configs"
export CONFIG_DIR
PATCHES_DIR="${ROOT_DIR}/patches"
export PATCHES_DIR
KEYS_BUILD_DIR="${BUILD_DIR}/keys"
export KEYS_BUILD_DIR
ROOTFS_BUILD_DIR="${BUILD_DIR}/rootfs"
export ROOTFS_BUILD_DIR
ENFORCEMENT_DIR="${ROOT_DIR}/tools/enforcement"
export ENFORCEMENT_DIR
BMK_SRC_DIR="${ROOT_DIR}/bmk-src"
export BMK_SRC_DIR
POLICY_DIR="${ROOT_DIR}/policies"
export POLICY_DIR
TOOL_DIR="${ROOT_DIR}/tools"
export TOOL_DIR
TEST_DIR="${ROOT_DIR}/tests"
export TEST_DIR
MOUNT_DIR="$ROOTFS_BUILD_DIR/mnt/rootfs"
export MOUNT_DIR
TRACING_DIR="${TOOL_DIR}/tracing"
export TRACING_DIR
QEMU_PIDFILE=${BUILD_DIR}/qemu_pid

# kernel/rootfs/vm stuff
KERNEL_VERSION='6.2.0'
export KERNEL_VERSION
KERNEL_SRC_DIR="${ROOT_DIR}/linux-${KERNEL_VERSION}"
export KERNEL_SRC_DIR
ROOTFS_IMG="${ROOTFS_BUILD_DIR}/rootfs.img"
export ROOTFS_IMG
ROOTFS_IMG_GB="32"
export ROOTFS_IMG_GB
VM_RAM_GB="32"
export VM_RAM_GB
KERNEL_CONFIGS="vanilla vanilla-membench safeslab safeslab-membench"
export KERNEL_CONFIGS
BENCHMARKS="lmbench pts"
export BENCHMARKS
VMPORT=6969

# scripts
ENFORCE="${ROOT_DIR}/tools/enforce.sh"
VM_SANITY_SCRIPT="${VM_ROOT_DIR}/run-sanity.sh"
export TEST_SCRIPT
VM_LMBENCH_SCRIPT="${VM_ROOT_DIR}/run-lmbench.sh"
export LMBENCH_SCRIPT
VM_PTS_SCRIPT="${VM_ROOT_DIR}/run-pts.sh"
export VM_PTS_SCRIPT
VM_MEMBENCH_SCRIPT="${VM_ROOT_DIR}/run-membench.sh"
export MEMBENCH_SCRIPT
BUILD_SCRIPT="${TOOL_DIR}/build.sh"
export BUILD_SCRIPT
RUN_SCRIPT="${TOOL_DIR}/run.sh"
export RUN_SCRIPT
CLEAN_SCRIPT="${TOOL_DIR}/clean.sh"
export CLEAN_SCRIPT
DEBUG_SCRIPT="${TOOL_DIR}/debug.sh"
export DEBUG_SCRIPT
GUEST_KERNEL_CMDLINE="root=/dev/sda rw console=ttyS0 quiet nokaslr net.ifnames=0 clearcpuid=58 noresume"
export GUEST_KERNEL_CMDLINE

# color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
RESET='\033[0m'

# logging
do_log()
{
    echo -e \
        "[+][$(TZ='America/New_York' /usr/bin/date +%Y/%m/%d\ @\ %H:%M:%S)] " \
        "${GREEN}${1}${RESET}"
}

do_warn()
{
    echo -e \
        "[!][$(TZ='America/New_York' /usr/bin/date +%Y/%m/%d\ @\ %H:%M:%S)] " \
        "${ORANGE}${1}${RESET}"
}

do_error()
{
    echo -e \
        "[Error][$(TZ='America/New_York' /usr/bin/date +%Y/%m/%d\ @\ %H:%M:%S)] " \
        "${RED}${1}${RESET}" 1>&2
    exit 1
}

verify_config_opt()
{
    local config="${1}"

    for c in ${KERNEL_CONFIGS}; do
        if [[ ${config} == "${c}" ]]; then
            return
        fi
    done

    do_error "Invalid config: ${config}."
}

verify_suite_opt()
{
    local suite="${1}"

    if [[ ${suite} != "inheritance" && ${suite} != "exchange" ]]; then
        do_error "Invalid test suite: ${suite}."
    fi
}

verify_bmk_opt()
{
    local bmk="${1}"

    for b in ${BENCHMARKS}; do
        if [[ ${b} == "${bmk}" ]]; then
            return
        fi
    done

    do_error "Invalid benchmark: ${bmk}."
}

vmcmd()
{
    local cmd="${1}"

    ssh -p "${VMPORT}" -o UserKnownHostsFile=/dev/null \
        -o StrictHostKeyChecking=no -q root@localhost "${cmd}"
}

wait_vm()
{
    vmcmd "exit"
    while [[ ${?} -ne 0 ]]; do
        vmcmd "exit"
    done
}

vmcopy()
{
    local src="${1}"
    local dst="${2}"
    
    scp -r -P "${VMPORT}" -o UserKnownHostsFile=/dev/null \
        -o StrictHostKeyChecking=no -q root@localhost:"${src}" "${dst}"
}

vmcopyto()
{
    local src="${1}"
    local dst="${2}"

    scp -r -P "${VMPORT}" -o UserKnownHostsFile=/dev/null \
        -o StrictHostKeyChecking=no -q "${src}" root@localhost:"${dst}"
}

vmstart()
{
    local config="${1:-vanilla}"
    shift

    local kernel_image="${BUILD_DIR}/obj/${KERNEL_VERSION}-${config}/arch/x86/boot/bzImage"
    local initrd_image="${BUILD_DIR}/obj/${KERNEL_VERSION}-${config}/initrd.img-${KERNEL_VERSION}-${config}"
    local dbg=0
    local snapshot=""

    do_log "Starting ${config} VM."

    while [[ ${#} -gt 0 ]]; do
        case "${1}" in
            debug )
                dbg=1
                ;;

            snapshot )
                snapshot="-snapshot"
                ;;

            * )
                do_error "Invalid argument: ${1}."
                ;;
        esac
        shift
    done

    if [[ ${dbg} -eq 1 ]]; then
        # start me up
        qemu-system-x86_64 \
          -kernel "${kernel_image}" \
          -initrd "${initrd_image}" \
          -drive file="${ROOTFS_IMG}",index=0,media=disk,format=raw \
          -nographic \
          -append "${GUEST_KERNEL_CMDLINE}" \
          -m "${VM_RAM_GB}G" \
          -smp 16 \
          --enable-kvm \
          -device e1000,netdev=net0 \
          -netdev user,id=net0,hostfwd=tcp:127.0.0.1:${VMPORT}-:22 \
          -cpu host \
          -s \
          ${snapshot}
    else
        # start me up
        qemu-system-x86_64 \
          -kernel "${kernel_image}" \
          -initrd "${initrd_image}" \
          -drive file="${ROOTFS_IMG}",index=0,media=disk,format=raw \
          -nographic \
          -append "${GUEST_KERNEL_CMDLINE}" \
	  -m "${VM_RAM_GB}G" \
          -smp 16 \
          --enable-kvm \
          -device e1000,netdev=net0 \
          -netdev user,id=net0,hostfwd=tcp:127.0.0.1:${VMPORT}-:22 \
          -cpu host \
          -serial null\
          -pidfile ${QEMU_PIDFILE} \
          ${snapshot} > /dev/null &

        wait_vm
    fi
}

vmstop()
{
    vmcmd "shutdown -h now"

    # easier to just sleep for a few seconds instead of actually checking
    # if things shutdown correctly
    wait $(cat ${QEMU_PIDFILE})

    do_log "Stopped VM."
}
