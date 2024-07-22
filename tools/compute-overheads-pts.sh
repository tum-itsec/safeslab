#!/bin/bash


test_names=(
	"unpack-linux"
	"ffmpeg"
	"hackbench"
	"openssl (sign)"
	"openssl (verify)"
	"nginx"
	"apache"
	"gnupg"
	"sqlite"
	"redis"
)

test_outputs=(
	"Unpack-linux"
	"Ffmpeg"
	"Hackbench"
	"Openssl"
	"Openssl"
	"Nginx"
	"Apache"
	"Gnupg"
	"Sqlite"
	"Redis"
)

higher_is_better=(
	"0"
	"1"
	"0"
	"1"
	"1"
	"1"
	"1"
	"1"
	"1"
	"0"
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
		avg_vanilla=$(grep "${test_outputs[$i]}" $1 | tail -n1 | awk '{print $3}')
		avg_modified=$(grep "${test_outputs[$i]}" $2 | tail -n1 | awk '{print $3}')
		if [ ${higher_is_better[$i]} -eq "1" ]; then
			ohd=$(echo "scale=2; ${avg_vanilla}/${avg_modified}" | bc -l)
		else
			ohd=$(echo "scale=2; ${avg_modified}/${avg_vanilla}" | bc -l)
		fi
		echo "Overhead of ${test_names[$i]}: ${ohd}"
		product_modified=$(echo "scale=2; $product_modified*$ohd" | bc -l)
	done

	geomean=$(echo "scale=2; e(l(${product_modified})/${#test_names[@]})" | bc -l)
	echo "Geomean: $geomean"
}
main ${@}
