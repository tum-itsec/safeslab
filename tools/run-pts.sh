#!/bin/bash

FORCE_TIMES_TO_RUN=5
export FORCE_TIMES_TO_RUN

printf "5\n" | ./pts/phoronix-test-suite dry-run sqlite | grep "Average:" | sed 's/^/Sqlite/'

./pts/phoronix-test-suite dry-run unpack-linux | grep "Average:" | sed 's/^/Unpack-linux/'

printf "1\n1\n" | ./pts/phoronix-test-suite dry-run ffmpeg | grep "Average:" | sed 's/^/Ffmpeg/'

# we exclude this benchmark for now as it leads to occasional crashes
#printf "1\n" | ./pts/phoronix-test-suite dry-run build-linux-kernel | grep "Average:" | sed 's/^/Build-linux/'

printf "5\n1\n" | ./pts/phoronix-test-suite dry-run hackbench | grep "Average:" | sed 's/^/Hackbench/'

printf "1\n" | ./pts/phoronix-test-suite dry-run openssl | grep "Average:" | sed 's/^/Openssl/'

printf "1\n1\n" | ./pts/phoronix-test-suite dry-run redis | grep "Average:" | sed 's/^/Redis/'

printf "3\n" | ./pts/phoronix-test-suite dry-run nginx | grep "Average:" | sed 's/^/Nginx/'

printf "3\n" | ./pts/phoronix-test-suite dry-run apache | grep "Average:" | sed 's/^/Apache/'

./pts/phoronix-test-suite dry-run gnupg | grep "Average:" | sed 's/^/Gnupg/'
