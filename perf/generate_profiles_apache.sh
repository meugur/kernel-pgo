#!/bin/bash

set -e

CPU_SERVER=2
CPU_CLIENT=1
RUNS=5

OUTPUT_DIR=../profile-output/apache/stat
mkdir -p $OUTPUT_DIR

sudo taskset -c $CPU_SERVER apachectl -d /etc/apache2 -e info -DFOREGROUND &
PID=$!
echo "apache, pid $PID"

echo "first"
sudo perf stat -o "${OUTPUT_DIR}/apache-bench_1.log" \
    -e cycles,cycles:k,instructions,instructions:k -C $CPU_SERVER -r $RUNS -- \
    taskset -c $CPU_CLIENT ab -n 1000000 -c 10 127.0.0.1/ > /dev/null
echo "second"
sudo perf stat -o "${OUTPUT_DIR}/apache-bench_2.log" \
    -e L1-icache-load-misses,L1-icache-load-misses:k,iTLB-load-misses,iTLB-load-misses:k -C $CPU_SERVER -r $RUNS -- \
    taskset -c $CPU_CLIENT ab -n 1000000 -c 10 127.0.0.1/ > /dev/null

echo "killing pid $PID"
sudo kill -9 $PID
