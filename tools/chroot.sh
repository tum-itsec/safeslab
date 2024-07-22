#!/bin/bash

# Install basic utilities
apt install -y locales wget openssh-server unzip sudo 

# Enable promtless ssh to the machine for root
sed -i '/^root/ { s/:x:/::/ }' /etc/passwd
sed -i 's/\#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/\#PermitEmptyPasswords no/PermitEmptyPasswords yes/g' /etc/ssh/sshd_config

echo -e "auto eth0\niface eth0 inet dhcp" >> /etc/network/interfaces

sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

cd /root

./install-benchmarks.sh
