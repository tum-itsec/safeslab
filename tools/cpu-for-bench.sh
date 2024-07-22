#!/bin/bash

# set freq governor to performance (always tries to run at the max freq set in scaling_max_factor)
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# disable turbo boost
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# set min and max freq to a value supported by all cpus
echo 1800000 | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq
echo 1800000 | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq

# clear fs caches
echo 3 | sudo tee /proc/sys/vm/drop_caches && sync

# disable aslr
echo 0 | sudo tee /proc/sys/kernel/randomize_va_space

# disable swapping
sudo swapoff -a
