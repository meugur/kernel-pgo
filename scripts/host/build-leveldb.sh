#!/bin/bash -e

CXX=$(pwd)/buildroot/output/host/usr/bin/x86_64-buildroot-linux-gnu-g++

cd leveldb

mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build .

cp db_bench ../../overlay/root/db_bench_leveldb

