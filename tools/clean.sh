#!/bin/bash
set -e

# import cookie-cutter functions
source "$(dirname "${0}")"/common.sh

clean_kernel()
{
    local config_name="${1}"
    local build_dir="${BUILD_DIR}/obj/${KERNEL_VERSION}-${config_name}"

    rm -rf "${build_dir}"
}

clean_results()
{
    rm -rf "${RESULTS_DIR}"
}

clean_rootfs()
{
    sudo rm -rf "${ROOTFS_BUILD_DIR}"
}

print_usage()
{
    cat 1>&2 <<EOF
Usage: $(ps -o args= ${PPID} | cut -d' ' -f2) clean [options]

Options:
  help              print this help menu
  all               clean all kernels, rootfs, and results
  kernel <config>   clean kernel with config <config>
  rootfs            clean rootfs, including all tests and benchmarks
  results           clean results directory

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
            sudo rm -rf "${BUILD_DIR}"
            rm -rf "${RESULTS_DIR}"
            ;;

        kernel )
            config="${2}"
            verify_config_opt "${config}"
            clean_kernel "${config}"
            ;;

        rootfs )
            clean_rootfs
            ;;
	
        results )
            clean_results
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
