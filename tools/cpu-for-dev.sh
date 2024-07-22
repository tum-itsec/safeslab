#!/bin/bash

# set freq governor to powersave
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# enable turbo boost
echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# set min and max freq to the largest max supported by all cpus
echo 6500000 | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq
echo 100 | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq

# enable aslr
echo 2 | sudo tee /proc/sys/kernel/randomize_va_space

# enable swapping
sudo swapon -a
