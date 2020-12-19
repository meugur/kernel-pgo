#!/bin/bash

set -e

BUILD_DIR=~/dev/eecs/eecs582/kernel-pgo/linux-5.9.6
GCOV_DATA=~/dev/eecs/eecs582/kernel-pgo/gcov-data/redis

FILES=$(find $GCOV_DATA -depth -type f -name "*.gcda")

for FILE in ${FILES[@]}; do
    FLAT=$(echo $FILE | sed -r 's/[/]+/#/g')
    HEAD=${FLAT##*redis}
    NEW="#home#meugur#dev#eecs#eecs582#kernel-pgo#linux-5.9.6$HEAD"
    echo $GCOV_DATA/$NEW
    cp $FILE $BUILD_DIR/$NEW
done
