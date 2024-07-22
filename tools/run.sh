#!/bin/bash

# import cookie-cutter functions
source "$(dirname "${0}")"/common.sh

run_sanity()
{
    mkdir -p "${RESULTS_DIR}"
    
    vmstart safeslab snapshot
    vmcmd "${VM_SANITY_SCRIPT}"
    vmstop
}

run_performance()
{
    local bmk="${1}"

    mkdir -p "${RESULTS_DIR}"

    case "${bmk}" in
    
        lmbench )
            # get LMBench baseline results
            vmstart vanilla snapshot
            vmcmd "${VM_LMBENCH_SCRIPT} |& tee /tmp/lmbench-vanilla.log"
            vmcopy "/tmp/lmbench-vanilla.log" "${RESULTS_DIR}"
            vmstop

            # get the LMBench results for Safeslab 
            vmstart safeslab snapshot
            vmcmd "${VM_LMBENCH_SCRIPT} |& tee /tmp/lmbench-safeslab.log"
            vmcopy "/tmp/lmbench-safeslab.log" "${RESULTS_DIR}"
            vmstop
            ;;

        pts )
            # get PTS baseline results
            vmstart vanilla snapshot
            vmcmd "${VM_PTS_SCRIPT} | tee /tmp/pts-vanilla.log"
            vmcopy "/tmp/pts-vanilla.log" "${RESULTS_DIR}"
            vmstop

            # get the PTS results for Safeslab 
            vmstart safeslab snapshot
            vmcmd "${VM_PTS_SCRIPT} | tee /tmp/pts-safeslab.log"
            vmcopy "/tmp/pts-safeslab.log" "${RESULTS_DIR}"
            vmstop
            ;;
        * )
            do_error "Invalid benchmark: ${bmk}."
            ;;
    esac
}

run_membench()
{
    vmstart vanilla-membench snapshot
    vmcmd "${VM_MEMBENCH_SCRIPT} slub | tee /tmp/membench-vanilla.log"
    vmcopy "/tmp/membench-vanilla.log" "${RESULTS_DIR}"
    vmstop

    vmstart safeslab-membench snapshot
    vmcmd "${VM_MEMBENCH_SCRIPT} safeslab | tee /tmp/membench-safeslab.log"
    vmcopy "/tmp/membench-safeslab.log" "${RESULTS_DIR}"
    vmstop
}

print_usage()
{
    cat 1>&2 <<EOF
Usage: $(ps -o args= ${PPID} | cut -d' ' -f2) run [options]

Options:
  help                  print this help menu
  sanity                check that Safeslab boots and initializes properly 
  performance <bmk>     evaluate performance with benchmark <bmk>
  membench     	        evaluate memory overhead

Performance benchmarks <bmk>:
  lmbench               LMBench
  pts                   Phoronix Test Suite
EOF
}

main()
{
    # check for command line arguments
    if [[ ${#} == 0 ]]; then
        print_usage
        exit 1
    fi

    case "${1}" in
        sanity )
            run_sanity
            ;;

        performance )
            bmk="${2}"
            verify_bmk_opt "${bmk}"
            run_performance "${bmk}"
            ;;

        membench )
            run_membench
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
