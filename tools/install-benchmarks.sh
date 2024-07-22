#!/bin/bash

# Install basic utilities
apt install -y wget unzip 

######### PTS #########

wget https://github.com/phoronix-test-suite/phoronix-test-suite/archive/refs/heads/master.zip
unzip master.zip
rm master.zip
mv phoronix-test-suite-master pts

# PTS deps
apt install -y php-cli php-xml git 

# Install PTS Tests
./pts/phoronix-test-suite install sqlite unpack-linux build-linux-kernel hackbench openssl redis nginx apache gnupg

# Sometimes the first installation attempt fails, retry
./pts/phoronix-test-suite install gnupg

# Dep for FFmpeg
mkdir -p "/var/lib/phoronix-test-suite/download-cache/"
wget "https://bitbucket.org/multicoreware/x265_git/downloads/x265_3.6.tar.gz"
mv "x265_3.6.tar.gz" "/var/lib/phoronix-test-suite/download-cache/"

# Install PTS FFmpeg
./pts/phoronix-test-suite install ffmpeg 

######### LMbench #########

wget https://github.com/AndrewFasano/lmbench/archive/refs/heads/master.zip 
unzip master.zip
rm master.zip
mv lmbench-master lmbench

# LMbench deps
apt install -y build-essential

# Build LMbench
cd lmbench
make -j"$(nproc)"

cd -
