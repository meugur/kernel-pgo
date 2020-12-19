#!/bin/bash

set -e

CPU_SERVER=2
CPU_CLIENT=1
RUNS=5

OUTPUT_DIR=../profile-output/memcached/stat-mc-bench-cpu-double
mkdir -p $OUTPUT_DIR

sudo taskset -c $CPU_SERVER /usr/local/memcached/bin/memcached &
PID=$!
echo "memcached, pid $PID"

echo "first"
sudo perf stat -o "${OUTPUT_DIR}/mc-benchmark-prof_1.log" \
    -e cycles,cycles:k,instructions,instructions:k -C $CPU_SERVER -r $RUNS -- \
    taskset -c $CPU_CLIENT ./mc-benchmark -n 1000000 -d 3  > /dev/null
echo "second"
sudo perf stat -o "${OUTPUT_DIR}/mc-benchmark-prof_2.log" \
    -e L1-icache-load-misses,L1-icache-load-misses:k,iTLB-load-misses,iTLB-load-misses:k -C $CPU_SERVER -r $RUNS -- \
    taskset -c $CPU_CLIENT ./mc-benchmark -n 1000000 -d 3  > /dev/null

echo "killing pid $PID"
kill -9 $PID

