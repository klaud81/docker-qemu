#!/bin/bash
sleep 2 
set -e
set -x
sudo apt install cpu-checker

kvm-ok

sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils -y

sudo adduser `id -un` kvm

virsh list --all

sudo ls -la /var/run/libvirt/libvirt-sock

ls -l /dev/kvm

# (options)
#sudo apt-get install virt-manager


