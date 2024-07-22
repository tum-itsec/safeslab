#!/bin/bash

# import cookie-cutter functions
source "$(dirname "${0}")"/common.sh

# build the rootfs
build_rootfs()
{
    mkdir -p "${ROOTFS_BUILD_DIR}"

    cd "${ROOTFS_BUILD_DIR}"

    # check if tools are installed
    command -v sudo debootstrap >/dev/null 2>&1 || { echo >&2 "I require debootstrap but it's not installed. Aborting."; exit 1; }

    command -v sudo debootstrap >/dev/null 2>&1 || { echo >&2 "I require qemu-img but it's not installed. Aborting."; exit 1; }

    if [ -z grep "pku" /proc/cpuinfo ]
    then
	echo >&2 "I require PKU but it's not supported by your hardware. Aborting."
	exit 1
    fi

    qemu-img create "${ROOTFS_IMG}" "${ROOTFS_IMG_GB}G" || exit 1
    sudo mkfs -t ext4 "${ROOTFS_IMG}"
   
    # mount the rootfs image
    mkdir -p "${MOUNT_DIR}"
    sudo mount -o loop "${ROOTFS_IMG}" "${MOUNT_DIR}"

    # install baseline rootfs: dirs, utilities, libs, etc.
    sudo debootstrap bullseye "${MOUNT_DIR}"

    # copy the necessary stuff inside
    sudo cp ${TOOL_DIR}/chroot.sh "${MOUNT_DIR}/${VM_ROOT_DIR}"
    sudo cp ${TOOL_DIR}/install-benchmarks.sh "${MOUNT_DIR}/${VM_ROOT_DIR}"

    # mount proc for chroot
    sudo mkdir -p "${MOUNT_DIR}/proc"
    sudo mount -t proc /proc "${MOUNT_DIR}/proc"
 
    sudo mkdir -p "${MOUNT_DIR}/sys"
    sudo mount -t sysfs /sys "${MOUNT_DIR}/sys"

    # chroot and setup env 
    sudo chroot ${MOUNT_DIR} ${VM_ROOT_DIR}/chroot.sh

    # copy benchmarks scripts
    sudo cp ${TOOL_DIR}/run-pts.sh ${MOUNT_DIR}/${VM_ROOT_DIR}
    sudo cp ${TOOL_DIR}/run-lmbench.sh ${MOUNT_DIR}/${VM_ROOT_DIR}
    sudo cp ${TOOL_DIR}/run-membench.sh ${MOUNT_DIR}/${VM_ROOT_DIR}
    sudo cp ${TOOL_DIR}/run-sanity.sh ${MOUNT_DIR}/${VM_ROOT_DIR}

    # unmount proc and sys 
    sudo umount "${MOUNT_DIR}/proc"
    sudo umount "${MOUNT_DIR}/sys"
    
    sudo rm -rf "${MOUNT_DIR}/proc"
    sudo rm -rf "${MOUNT_DIR}/sys"
    
    # unmount the rootfs image
    sudo umount "${MOUNT_DIR}"

    sync
}

# build the kernel
build_kernel()
{
    local config_name="${1}"
    local kernel_config="${CONFIG_DIR}/config-${KERNEL_VERSION}-${config_name}+"
    local build_dir="${BUILD_DIR}/obj/${KERNEL_VERSION}-${config_name}"
    local initrd_dir="${build_dir}/initrd"
    local src_dir
    local patch

    mkdir -p "${build_dir}"
    tar -xzf "${TOOL_DIR}/initrd.tar.gz" -C ${build_dir}
    
    mkdir -p "${BUILD_DIR}/src"
    
    if [ ${config_name} = "safeslab-membench" ] || [ ${config_name} = "safeslab" ]; then
	    src_dir="${BUILD_DIR}/src/${KERNEL_VERSION}-safeslab"
	    patch="${PATCHES_DIR}/${KERNEL_VERSION}-safeslab.patch"
    elif [ ${config_name} = "vanilla-membench" ] || [ ${config_name} = "vanilla" ]; then
	    src_dir="${BUILD_DIR}/src/${KERNEL_VERSION}-vanilla"
	    patch="${PATCHES_DIR}/${KERNEL_VERSION}-vanilla.patch"
    fi;
    
    if [ ! -d "$src_dir" ]; then
	cp -r "${KERNEL_SRC_DIR}" "$src_dir"
	cd "${src_dir}"
	patch -p1 < ${patch} || exit 1
	cd -
    fi;
    
    cd "${src_dir}"
    
    cp "${kernel_config}" "${build_dir}/.config"
    make O="${build_dir}" -j"$(nproc)"

    INSTALL_MOD_PATH="${initrd_dir}/usr"
    export INSTALL_MOD_PATH
    make O="${build_dir}" -j"$(nproc)" modules_install
    cd ${initrd_dir}
    find . | cpio --quiet -o -H newc -R 0:0 | zstd -q -9 -c > "${build_dir}/initrd.img-${KERNEL_VERSION}-${config_name}"
    cd -

    if [ ${config_name} = "safeslab-membench" ]; then
	   cd safeslab-membench
	   make O="${build_dir}" -j"$(nproc)"
	   cd -
    elif [ ${config_name} = "vanilla-membench" ]; then
	   cd slub-membench
	   make O="${build_dir}" -j"$(nproc)"
	   cd -
    fi

    vmstart "${config_name}"
    if [ ${config_name} = "safeslab-membench" ]; then
	    vmcopyto "./safeslab-membench/safeslab_membench.ko" "${VM_ROOT_DIR}"
    elif [ ${config_name} = "vanilla-membench" ]; then
	    vmcopyto "./slub-membench/slub_membench.ko" "${VM_ROOT_DIR}"
    fi
    vmcmd "echo 'Hello from ${config_name} VM!'"
    vmstop
}

print_usage()
{
    cat 1>&2 <<EOF
Usage: $(ps -o args= ${PPID} | cut -d' ' -f2) build [options]

Options:
  help              print this help menu
  all               build all kernels and rootfs
  all-kernels       build all kernels
  kernel <config>   build kernel with config <config>
  rootfs            build rootfs, including all tests and benchmarks

Configs <config>:
  vanilla           Linux kernel default (baseline) configuration
  vanilla-membench  Linux kernel default (baseline) configuration instrumented for collecting memory stats 
  safeslab          Linux kernel hardened with Safeslab
  safeslab-membench Linux kernel hardened with Safeslab and instrumented for collecting memory stats
EOF
}

main()
{
    local config bmk

    # check for command line arguments
    if [[ ${#} == 0 ]]; then
        print_usage
        exit 1
    fi

    case "${1}" in
        all )
            build_rootfs
            for config in ${KERNEL_CONFIGS}; do
                build_kernel "${config}"
            done
            ;;
	
        all-kernels )
            for config in ${KERNEL_CONFIGS}; do
                build_kernel "${config}"
            done
            ;;

        kernel )
            config="${2}"
            verify_config_opt "${config}"
            build_kernel "${config}"
            ;;

        rootfs )
            build_rootfs
            ;;
        
        help )
            print_usage
            ;;

        * )
            do_error "Invalid argument: ${1}."
            ;;
    esac
}
main ${@}
