#!/bin/bash

membench_test_names=(
	"Boot"
	"Hackbench"
	"Nginx"
	"Redis"
	"SQlite"
	"Apache"
)

main()
{
	if [[ ${#} != 2 ]]; then
		echo "Usage: ${0} results-file-vanilla results-file-modified"
		exit 1
	fi

	for i in "${!membench_test_names[@]}"
	do
		# Max RSS	
		max_rss_vanilla=$(grep -m $(( $i+1 )) "max RSS by SLUB" $1 | tail -n1 | awk '{print $5}')
		max_rss_safeslab=$(grep -m $(( $i+1 )) "max RSS by Safeslab" $2 | tail -n1 | awk '{print $5}')
		ohd_max_rss=$(echo "scale=2; $max_rss_safeslab/$max_rss_vanilla" | bc -l)
		echo "Max RSS overhead of ${membench_test_names[$i]}: $ohd_max_rss"

		# Alloc'ed
		allocs_vanilla=$(grep -m $(( $i+1 )) "total page allocations by SLUB" $1 | tail -n1 | awk '{print $5}')
		allocs_safeslab=$(grep -m $(( $i+1 )) "total page allocations by Safeslab" $2 | tail -n1 | awk '{print $5}')
		ohd_allocs=$(echo "scale=2; $allocs_safeslab/$allocs_vanilla" | bc -l)
		echo "Total alloc'ed overhead of ${membench_test_names[$i]}: $ohd_allocs"

		# Freed
		freed_worcu_vanilla=$(grep -m $(( $i+1 )) "total page frees w/o RCU by SLUB" $1 | tail -n1 | awk '{print $5}')
		freed_wrcu_vanilla=$(grep -m $(( $i+1 )) "total page frees w/ RCU by SLUB" $1 | tail -n1 | awk '{print $5}')
		freed_vanilla=$(( $freed_worcu_vanilla+$freed_wrcu_vanilla ))
		freed_worcu_safeslab=$(grep -m $(( $i+1 )) "total page frees w/o RCU by Safeslab" $2 | tail -n1 | awk '{print $5}')
		freed_wrcu_safeslab=$(grep -m $(( $i+1 )) "total page frees w/ RCU by Safeslab" $2 | tail -n1 | awk '{print $5}')
		freed_safeslab=$(( $freed_worcu_safeslab+$freed_wrcu_safeslab ))
		ohd_freed=$(echo "scale=2; $freed_safeslab/$freed_vanilla" | bc -l)
		echo "Total freed overhead of ${membench_test_names[$i]}: $ohd_freed"

		echo "==============================="
	done
}
main ${@}
