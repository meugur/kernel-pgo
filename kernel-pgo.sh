#!/bin/bash

set -e

GCOV_DATA=~/dev/eecs/eecs582/kernel-pgo/gcov-data/redis

cd linux-5.9.6

make clean
make KCFLAGS="-fprofile-use=$GCOV_DATA -fprofile-correction -Wno-error=coverage-mismatch" -j12 2>&1 | tee output.log
SUCCESS=$?
echo "FINISHED!"
echo "$SUCCESS"
