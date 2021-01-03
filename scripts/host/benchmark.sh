#!/bin/bash

set -e

NO_GCOV=0

BENCHMARK=$1
BENCH_OUTPUT=${2:-temp.txt}
TIMEOUT=2m

# Specific binaries
MCBENCH=$(pwd)/mc-benchmark/mc-benchmark
SYSBENCH_MYSQL=$(pwd)/sysbench-0.4.12.16/sysbench/sysbench
SYSBENCH_PGSQL=/usr/bin/sysbench

REDIS_PORT=7369
MEMCACHED_PORT=7369
NGINX_PORT=1080
APACHE_PORT=1080
MYSQL_PORT=3306
PGSQL_PORT=5432

REDIS_BENCH_FLAGS=(
    '-h 127.0.0.1'
    "-p $REDIS_PORT"
    '-n 200000'
    '-c 20'
    '-l'
)
MC_BENCH_FLAGS=(
    '-h 127.0.0.1'
    "-p $MEMCACHED_PORT"
    '-n 200000'
    '-c 20'
    '-l'
)
NGINX_BENCH_FLAGS=(
    '-t 120'
    '-n 1000000'
    '-c 20'
    "http://127.0.0.1:$NGINX_PORT/"
)
APACHE_BENCH_FLAGS=(
    '-t 120'
    '-n 1000000'
    '-c 20'
    "http://127.0.0.1:$APACHE_PORT/"
)
LEVELDB_BENCH_FLAGS=(
    '--db=/root/leveldbbench'
    '--num=5800000'
    '--benchmarks=fillseq,fillrandom,readseq,readrandom,deleteseq,deleterandom,stats'
)
ROCKSDB_BENCH_FLAGS=(
    '--db=/root/rocksdbbench'
    '--num=5800000'
    '--benchmarks=fillseq,fillrandom,readseq,readrandom,deleteseq,deleterandom,stats'
)
MYSQL_PREP_FLAGS=(
    '--test=oltp'
    '--db-driver=mysql'
    '--report-interval=2'
    '--oltp-table-size=10000000'
    '--num-threads=4'
    '--mysql-host=127.0.0.1'
    "--mysql-port=$MYSQL_PORT"
    '--mysql-db=sysbench'
    '--mysql-user=sysbench'
    '--mysql-password=password'
    'prepare'
)
MYSQL_RUN_FLAGS=(
    '--test=oltp'
    '--db-driver=mysql'
    '--report-interval=2'
    '--oltp-table-size=10000000'
    '--num-threads=16'
    '--max-time=120'
    '--max-requests=0'
    '--mysql-host=127.0.0.1'
    "--mysql-port=$MYSQL_PORT"
    '--mysql-db=sysbench'
    '--mysql-user=sysbench'
    '--mysql-password=password'
    'run'
)
PGSQL_PREP_FLAGS=(
    '--db-driver=pgsql'
    '--table_size=10000000'
    '--tables=1'
    '--threads=4'
    '--pgsql-host=127.0.0.1'
    "--pgsql-port=$PGSQL_PORT"
    '--pgsql-db=sysbench'
    '--pgsql-user=sysbench'
    '--pgsql-password=password'
    'oltp_read_write'
    'prepare'
)
PGSQL_RUN_FLAGS=(
    '--db-driver=pgsql'
    '--report-interval=2'
    '--table_size=10000000'
    '--tables=1'
    '--threads=16'
    '--max-time=120'
    '--max-requests=0'
    '--pgsql-host=127.0.0.1'
    "--pgsql-port=$PGSQL_PORT"
    '--pgsql-db=sysbench'
    '--pgsql-user=sysbench'
    '--pgsql-password=password'
    'oltp_read_write'
    'run'
)

guest_cmd() {
    echo "$1"
    ssh root@localhost -p 2222 "$1"
}

time_guest_cmd() {
    echo "$1"
    time ssh root@localhost -p 2222 "$1"
}

service() {
    set +e
    guest_cmd "/etc/init.d/$1 $2"
    set -e
}

start_gcov() {
    if [[ $NO_GCOV -eq 0 ]]; then
        guest_cmd "echo 1 | tee /sys/kernel/debug/gcov/reset"
    fi
}

setup() {
    guest_cmd "date"
    guest_cmd "echo 0 | tee /proc/sys/kernel/randomize_va_space"
    guest_cmd "echo 1 | tee /proc/sys/net/ipv4/tcp_tw_reuse"
    start_gcov
}

collect() {
    if [[ $NO_GCOV -eq 0 ]]; then
        guest_cmd "cd / && time ./root/gather.sh $BENCHMARK.tar.gz"
    fi
}

guest_shutdown() {
    guest_cmd poweroff
}

case "$BENCHMARK" in
    redis)
        setup
        guest_cmd "redis-server --port $REDIS_PORT --protected-mode no &"
        set +e
        timeout $TIMEOUT redis-benchmark ${REDIS_BENCH_FLAGS[@]} | tee $BENCH_OUTPUT
        set -e
        collect
        guest_shutdown
        ;;
    memcached)
        setup
        guest_cmd "memcached -p $MEMCACHED_PORT -u nobody &"
        set +e
        timeout $TIMEOUT $MCBENCH ${MC_BENCH_FLAGS[@]} | tee $BENCH_OUTPUT
        set -e
        collect
        guest_shutdown
        ;;
    nginx)
        setup
        guest_cmd "nginx"
        ab ${NGINX_BENCH_FLAGS[@]} | tee $BENCH_OUTPUT
        collect
        guest_shutdown
        ;;
    apache)
        setup
        guest_cmd "httpd"
        ab ${APACHE_BENCH_FLAGS[@]} | tee $BENCH_OUTPUT
        collect
        guest_shutdown
        ;;
    leveldb)
        FLAGS=${LEVELDB_BENCH_FLAGS[@]}
        setup
        guest_cmd "mkdir -p /root/leveldbbench"
        time_guest_cmd "./db_bench_leveldb $FLAGS" | tee $BENCH_OUTPUT
        collect
        guest_cmd "rm -rf /root/leveldbbench"
        guest_shutdown
        ;;
    rocksdb)
        FLAGS=${ROCKSDB_BENCH_FLAGS[@]}
        setup
        guest_cmd "mkdir -p /root/rocksdbbench"
        time_guest_cmd "./db_bench_rocksdb $FLAGS" | tee $BENCH_OUTPUT
        collect
        guest_cmd "rm -rf /root/rocksdbbench"
        guest_shutdown
        ;;
    mysql)
        case "$3" in
            prepare)
                guest_cmd "date"
                service "S50redis" "stop"
                service "S50nginx" "stop"
                service "S50apache" "stop"
                service "S50postgresql" "stop"
                service "S97mysqld" "restart"
                guest_cmd "sleep 5"
                guest_cmd "mysql -u root -e \"CREATE DATABASE sysbench;\""
                guest_cmd "mysql -u root -e \"CREATE USER 'sysbench'@'10.0.2.2' IDENTIFIED BY 'password';\""
                guest_cmd "mysql -u root -e \"GRANT ALL PRIVILEGES ON *.* TO 'sysbench'@'10.0.2.2' IDENTIFIED BY 'password';\""
                $SYSBENCH_MYSQL ${MYSQL_PREP_FLAGS[@]}
                ;;
            run)
                guest_cmd "date"
                service "S50redis" "stop"
                service "S50nginx" "stop"
                service "S50apache" "stop"
                service "S50postgresql" "stop"
                service "S97mysqld" "restart"
                guest_cmd "sleep 5"
                guest_cmd "echo 0 | tee /proc/sys/kernel/randomize_va_space"
                guest_cmd "echo 1 | tee /proc/sys/net/ipv4/tcp_tw_reuse"
                start_gcov
                $SYSBENCH_MYSQL ${MYSQL_RUN_FLAGS[@]} | tee $BENCH_OUTPUT
                collect
                guest_shutdown
                ;;
            drop)
                guest_cmd "date"
                service "S50redis" "stop"
                service "S50nginx" "stop"
                service "S50apache" "stop"
                service "S50postgresql" "stop"
                service "S97mysqld" "restart"
                guest_cmd "sleep 5"
                guest_cmd "mysql -u root -e \"DROP DATABASE sysbench;\""
                guest_cmd "mysql -u root -e \"DROP USER 'sysbench'@'10.0.2.2';\""
                ;;
            *)
                echo "MySQL usage: $0 $BENCHMARK {prepare|run|drop}"
                exit 1
                ;;
        esac
        ;;
    postgresql)
        case "$3" in
            prepare)
                guest_cmd "date"
                service "S50redis" "stop"
                service "S50nginx" "stop"
                service "S50apache" "stop"
                service "S97mysqld" "stop"
                service "S50postgresql" "restart"
                guest_cmd "sleep 5"
                guest_cmd "psql -U postgres -c \"CREATE DATABASE sysbench;\""
                guest_cmd "psql -U postgres -c \"CREATE USER sysbench WITH PASSWORD 'password';\""
                guest_cmd "psql -U postgres -c \"GRANT ALL PRIVILEGES ON DATABASE sysbench TO sysbench;\""
                $SYSBENCH_PGSQL ${PGSQL_PREP_FLAGS[@]}
                ;;
            run)
                guest_cmd "date"
                service "S50redis" "stop"
                service "S50nginx" "stop"
                service "S50apache" "stop"
                service "S97mysqld" "stop"
                service "S50postgresql" "restart"
                guest_cmd "sleep 5"
                guest_cmd "echo 0 | tee /proc/sys/kernel/randomize_va_space"
                guest_cmd "echo 1 | tee /proc/sys/net/ipv4/tcp_tw_reuse"
                start_gcov
                $SYSBENCH_PGSQL ${PGSQL_RUN_FLAGS[@]} | tee $BENCH_OUTPUT
                collect
                guest_shutdown
                ;;
            drop)
                guest_cmd "date"
                service "S50redis" "stop"
                service "S50nginx" "stop"
                service "S50apache" "stop"
                service "S97mysqld" "stop"
                service "S50postgresql" "restart"
                guest_cmd "sleep 5"
                guest_cmd "psql -U postgres -c \"DROP DATABASE sysbench;\""
                guest_cmd "psql -U postgres -c \"DROP USER sysbench;\""
                ;;
            *)
                echo "PostgreSQL usage: $0 $BENCHMARK {prepare|run|drop}"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Usage: $0 {redis|memcached|nginx|apache|leveldb|rocksdb|mysql|postgresql}"
        exit 1
        ;;
esac

