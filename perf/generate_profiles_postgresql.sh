#!/bin/bash

set -e

CPU_SERVER=2
CPU_CLIENT=1
RUNS=5

OUTPUT_DIR=profile-output/postgresql/stat
mkdir -p $OUTPUT_DIR
sudo service postgresql restart
PID=$!
echo "postgresql, pid $PID"

sudo taskset \
    -c $CPU_CLIENT \
    sysbench \
    --db-driver=pgsql \
    --table_size=1000000 \
    --tables=1 \
    --threads=4 \
    --pgsql-host=127.0.0.1 \
    --pgsql-port=5433 \
    --pgsql-db=sysbench \
    --pgsql-user=sysbench \
    --pgsql-password=password \
    oltp_read_write \
    prepare

echo "starting workload${TEST}_1"
sudo perf stat -o "${OUTPUT_DIR}/sysbench_1.log" \
    -e cycles,cycles:k,instructions,instructions:k -C $CPU_SERVER -r $RUNS -- \
    taskset \
    -c $CPU_CLIENT \
    sysbench \
    --db-driver=pgsql \
    --report-interval=2 \
    --table_size=1000000 \
    --tables=1 \
    --threads=16 \
    --max-requests=0 \
    --pgsql-host=127.0.0.1 \
    --pgsql-port=5433 \
    --pgsql-db=sysbench \
    --pgsql-user=sysbench \
    --pgsql-password=password \
    oltp_read_write \
    run

echo "starting workload${TEST}_2"
sudo perf stat -o "${OUTPUT_DIR}/sysbench_2.log" \
    -e L1-icache-load-misses,L1-icache-load-misses:k,iTLB-load-misses,iTLB-load-misses:k -C $CPU_SERVER -r $RUNS -- \
    taskset \
    -c $CPU_CLIENT \
    sysbench \
    --db-driver=pgsql \
    --report-interval=2 \
    --table_size=1000000 \
    --tables=1 \
    --threads=16 \
    --max-requests=0 \
    --pgsql-host=127.0.0.1 \
    --pgsql-port=5433 \
    --pgsql-db=sysbench \
    --pgsql-user=sysbench \
    --pgsql-password=password \
    oltp_read_write \
    run

echo "killing pid $PID"
sudo kill -9 $PID
