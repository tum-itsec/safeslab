#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo 'Please provide desired allocator and rerun!'
    exit 0
fi

ALLOCATOR=$1

# collect mem stats after Boot
insmod ${ALLOCATOR}_membench.ko
rmmod ${ALLOCATOR}_membench.ko

FORCE_TIMES_TO_RUN=1
export FORCE_TIMES_TO_RUN

# exclude this benchmark for now as it leads to occasional crashes
#printf "1\n" | ./pts/phoronix-test-suite dry-run build-linux-kernel &> /dev/null
## collect mem stats after the Build Linux benchmark
#insmod ${ALLOCATOR}_membench.ko
#rmmod ${ALLOCATOR}_membench.ko

printf "5\n1\n" | ./pts/phoronix-test-suite dry-run hackbench &> /dev/null
# collect mem stats after the Hackbench benchmark
insmod ${ALLOCATOR}_membench.ko
rmmod ${ALLOCATOR}_membench.ko

printf "3\n" | ./pts/phoronix-test-suite dry-run nginx &> /dev/null
# collect mem stats after the Nginx benchmark
insmod ${ALLOCATOR}_membench.ko
rmmod ${ALLOCATOR}_membench.ko

printf "1\n1\n" | ./pts/phoronix-test-suite dry-run redis &> /dev/null
# collect mem stats after the Redis benchmark
insmod ${ALLOCATOR}_membench.ko
rmmod ${ALLOCATOR}_membench.ko

printf "5\n" | ./pts/phoronix-test-suite dry-run sqlite &> /dev/null
# collect mem stats after the SQlite benchmark
insmod ${ALLOCATOR}_membench.ko
rmmod ${ALLOCATOR}_membench.ko

printf "3\n" | ./pts/phoronix-test-suite dry-run apache &> /dev/null
# collect mem stats after the Apache benchmark
insmod ${ALLOCATOR}_membench.ko
rmmod ${ALLOCATOR}_membench.ko

# dump all membench results
dmesg | grep "MEMBENCH"
