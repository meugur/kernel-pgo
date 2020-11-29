#!/bin/bash

set -e 

if [[ -z $1 ]]; then
    echo "Provide a linux version! i.e. linux-5.9.6"
    exit 1
fi

VERSION=$1
LINUXTAR="$VERSION.tar.xz"
if [[ ! -e $LINUXTAR ]]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v5.x/$LINUXTAR
fi

if [[ ! -d "${LINUXTAR%.tar.xz}" ]]; then
    xz -cd $LINUXTAR | tar xvf -
fi

