#!/bin/bash

set -e

CPU_SERVER=2
CPU_CLIENT=1
RUNS=5
TEST_NAMES=('a' 'b' 'c' 'd' 'e' 'f')

OUTPUT_DIR=../profile-output/mongodb/stat-ycsb
mkdir -p $OUTPUT_DIR

sudo taskset -c $CPU_SERVER mongod --dbpath /tmp/mongodb &
PID=$!
echo "mongodb, pid $PID"

for TEST in ${TEST_NAMES[@]}; do
	echo "loading workload${TEST}"
    WORKLOAD="workloads/workload${TEST}"
    sudo taskset -c $CPU_CLIENT ./bin/ycsb load mongodb -s -P $WORKLOAD > /dev/null

	echo "starting workload${TEST}_1"
    sudo perf stat -o "${OUTPUT_DIR}/workload${TEST}_1.log" \
        -e cycles,cycles:k,instructions,instructions:k -C $CPU_SERVER -r $RUNS -- \
        taskset -c $CPU_CLIENT ./bin/ycsb run mongodb -s -P $WORKLOAD > /dev/null
	echo "starting workload${TEST}_2"
    sudo perf stat -o "${OUTPUT_DIR}/workload${TEST}_2.log" \
        -e L1-icache-load-misses,L1-icache-load-misses:k,iTLB-load-misses,iTLB-load-misses:k -C $CPU_SERVER -r $RUNS -- \
        taskset -c $CPU_CLIENT ./bin/ycsb run mongodb -s -P $WORKLOAD > /dev/null

    echo "clearing db"
    mongo ycsb --eval "db.dropDatabase()"
done

echo "killing pid $PID"
kill -9 $PID
