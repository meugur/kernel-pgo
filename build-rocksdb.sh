#!/bin/bash -e

CXX=$(pwd)/buildroot/output/host/usr/bin/x86_64-buildroot-linux-gnu-g++

cd rocksdb

make -j8 db_bench DEBUG_LEVEL=0

cp db_bench ../overlay/root/db_bench_rocksdb

