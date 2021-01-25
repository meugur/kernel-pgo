#!/bin/bash

set -e 

KERNEL_PATH=$(pwd)/kernels/5.3/gcov/vmlinux
ROOT_FS_PATH=$(pwd)/images/ubuntu_base_20_04_1_kernel_5_3.img

qemu-system-x86_64 \
    -kernel $KERNEL_PATH \
    -boot c \
    -m 2048 \
    -hda $ROOT_FS_PATH \
    -append 'root=/dev/sda rw console=ttyS0 nokaslr' \
    -display none \
    -serial mon:stdio \
    -enable-kvm \
    -cpu host \
    -nic user,hostfwd=tcp::7369-:7369,hostfwd=tcp::1080-:80,hostfwd=tcp::2222-:22,hostfwd=tcp::3306-:3306,hostfwd=tcp::5432-:5432

