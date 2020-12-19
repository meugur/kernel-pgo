#!/bin/bash

set -e

CPU_SERVER=2
CPU_CLIENT=1
RUNS=5
TEST_NAMES=('a' 'b' 'c' 'd' 'e' 'f')

OUTPUT_DIR=../profile-output/redis/stat
mkdir -p $OUTPUT_DIR
sudo taskset -c $CPU_SERVER redis-server &
PID=$!
echo "redis, pid $PID"

for TEST in ${TEST_NAMES[@]}; do
	echo "loading workload${TEST}"
    WORKLOAD="workloads/workload${TEST}"
    sudo taskset -c $CPU_CLIENT ./bin/ycsb load redis -s -P $WORKLOAD -p "redis.host=127.0.0.1" -p "redis.port=6379" > /dev/null

	echo "starting workload${TEST}_1"
    sudo perf stat -o "${OUTPUT_DIR}/workload${TEST}_1.log" \
        -e cycles,cycles:k,instructions,instructions:k -C $CPU_SERVER -r $RUNS -- \
        taskset -c $CPU_CLIENT ./bin/ycsb run redis -s -P $WORKLOAD -p "redis.host=127.0.0.1" -p "redis.port=6379"  > /dev/null
	echo "starting workload${TEST}_2"
    sudo perf stat -o "${OUTPUT_DIR}/workload${TEST}_2.log" \
        -e L1-icache-load-misses,L1-icache-load-misses:k,iTLB-load-misses,iTLB-load-misses:k -C $CPU_SERVER -r $RUNS -- \
        taskset -c $CPU_CLIENT ./bin/ycsb run redis -s -P $WORKLOAD -p "redis.host=127.0.0.1" -p "redis.port=6379"  > /dev/null
done
echo "killing pid $PID"
sudo kill -9 $PID
