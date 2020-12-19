#!/bin/bash

set -e

CPU_SERVER=2
CPU_CLIENT=1
RUNS=5
TEST_NAMES=('ping_inline' 'ping-bulk' 'set' 'get' 'incr' 'lpush' 'rpush' 'lpop' 'rpop' 'sadd' 'hset' 'spop' 'lrange_100' 'lrange_300' 'lrange_500' 'lrange_600' 'mset')

OUTPUT_DIR=../profile-output/redis/stat-benchmark
mkdir -p $OUTPUT_DIR
sudo taskset -c $CPU_SERVER redis-server &
PID=$!
echo "redis, pid $PID"

echo "starting default 1"
sudo perf stat -o "${OUTPUT_DIR}/default_1.log" \
    -e cycles,cycles:k,instructions,instructions:k -C $CPU_SERVER -r $RUNS -- \
    taskset -c $CPU_CLIENT redis-benchmark > /dev/null
echo "starting default 2"
sudo perf stat -o "${OUTPUT_DIR}/default_2.log" \
    -e L1-icache-load-misses,L1-icache-load-misses:k,iTLB-load-misses,iTLB-load-misses:k -C $CPU_SERVER -r $RUNS -- \
    taskset -c $CPU_CLIENT redis-benchmark > /dev/null

for TEST in ${TEST_NAMES[@]}; do
	echo "starting ${TEST} 1"
    sudo perf stat -o "${OUTPUT_DIR}/${TEST}_1.log" \
        -e cycles,cycles:k,instructions,instructions:k -C $CPU_SERVER -r $RUNS -- \
        taskset -c $CPU_CLIENT redis-benchmark -t ${TEST} > /dev/null
	echo "starting ${TEST} 2"
    sudo perf stat -o "${OUTPUT_DIR}/${TEST}_2.log" \
        -e L1-icache-load-misses,L1-icache-load-misses:k,iTLB-load-misses,iTLB-load-misses:k -C $CPU_SERVER -r $RUNS -- \
        taskset -c $CPU_CLIENT redis-benchmark -t ${TEST} > /dev/null
done
echo "killing pid $PID"
sudo kill -9 $PID
