#!/bin/bash

test_names=(
	"fork+/bin/sh"
	"fork+execve"
	"fork+exit"
	"prot fault"
	"udp socket"
	"tcp socket"
	"unix socket"
	"pipe"
	"sig deliver"
	"sigaction"
	"select(10 tcp fds)"
	"select(500 tcp fds)"
	"select(10 fds)"
	"select(500 fds)"
	"open/close"
	"fstat"
	"stat"
	"write"
	"read"
	"syscall"
)

test_outputs=(
	"Process fork+/bin/sh"
	"Process fork+execve"
	"Process fork+exit"
	"Protection fault"
	"UDP latency using localhost"
	"TCP latency using localhost"
	"AF_UNIX sock stream latency"
	"Pipe latency"
	"Signal handler overhead"
	"Signal handler installation"
	"Select on 10 tcp fd"
	"Select on 500 tcp fd"
	"Select on 10 fd"
	"Select on 500 fd"
	"Simple open/close"
	"Simple fstat"
	"Simple stat"
	"Simple write"
	"Simple read"
	"Simple syscall"
)

product_modified=1

main()
{
	if [[ ${#} != 2 ]]; then
		echo "Usage: ${0} results-file-vanilla results-file-modified"
		exit 1
	fi

	for i in "${!test_names[@]}"
	do
		avg_vanilla=$(grep "${test_outputs[$i]}" $1 | awk -F ' ' '{ total += $(NF-1) } END { print total/NR }')
		avg_modified=$(grep "${test_outputs[$i]}" $2 | awk -F ' ' '{ total += $(NF-1) } END { print total/NR }')
		ohd=$(echo "scale=2; ${avg_modified}/${avg_vanilla}" | bc -l)
		echo "Overhead of ${test_names[$i]}: ${ohd}"
		product_modified=$(echo "scale=2; $product_modified*$ohd" | bc -l)
	done

	geomean=$(echo "scale=2; e(l(${product_modified})/${#test_names[@]})" | bc -l)
	echo "Geomean: $geomean"
}
main ${@}
