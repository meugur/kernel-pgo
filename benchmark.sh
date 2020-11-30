#!/bin/bash

set -e

REDIS_PORT=7369
MEMCACHED_PORT=7369
NGINX_PORT=1080
APACHE_PORT=1080
MYSQL_PORT=3306

MCBENCH=$(pwd)/mc-benchmark/mc-benchmark
SYSBENCH=$(pwd)/sysbench-0.4.12.16/sysbench/sysbench

echo "Starting $1 benchmark"

ssh root@localhost -p 2222 "
date
/etc/init.d/S50redis stop
/etc/init.d/S50nginx stop
/etc/init.d/S50apache stop
/etc/init.d/S50postgresql stop
/etc/init.d/S97mysqld stop
sleep 5
echo 0 | tee /proc/sys/kernel/randomize_va_space
echo 1 | tee /proc/sys/net/ipv4/tcp_tw_reuse
echo 1 | tee /sys/kernel/debug/gcov/reset
"

case "$1" in
    redis)
        ssh root@localhost -p 2222 "redis-server --port $REDIS_PORT --protected-mode no &"
        redis-benchmark -t set,get -h 127.0.0.1 -p $REDIS_PORT -q -n 1000000 -c 50
        ;;
    memcached)
        ssh root@localhost -p 2222 "memcached -p $MEMCACHED_PORT -u nobody &"
        $MCBENCH -h 127.0.0.1 -p $MEMCACHED_PORT -n 1000000 -c 50
        ;;
    nginx)
        ssh root@localhost -p 2222 "nginx"
        ab -n 1000000 -c 50 "http://127.0.0.1:$NGINX_PORT/"
        ;;
    apache)
        ssh root@localhost -p 2222 "httpd"
        ab -n 1000000 -c 50 "http://127.0.0.1:$APACHE_PORT/"
        ;;
    leveldb)
        ;;
    rocksdb)
        ;;
    mysql)
        ssh root@localhost -p 2222 "/etc/init.d/S97mysqld start"

        case "$2" in
            prepare)
                ssh root@localhost -p 2222 "mysql -u root -e \"CREATE DATABASE sysbench;\""
                ssh root@localhost -p 2222 "mysql -u root -e \"CREATE USER 'sysbench'@'10.0.2.2' IDENTIFIED BY 'password';\""
                ssh root@localhost -p 2222 "mysql -u root -e \"GRANT ALL PRIVILEGES ON *.* TO 'sysbench'@'10.0.2.2' IDENTIFIED BY 'password';\""
                $SYSBENCH \
                    --test=oltp \
                    --db-driver=mysql \
                    --oltp-table-size=10000000 \
                    --mysql-host=127.0.0.1 \
                    --mysql-port=$MYSQL_PORT \
                    --mysql-db=sysbench \
                    --mysql-user=sysbench \
                    --mysql-password=password \
                    prepare
                ;;
            run)
                $SYSBENCH \
                    --test=oltp \
                    --db-driver=mysql \
                    --oltp-table-size=10000000 \
                    --mysql-host=127.0.0.1 \
                    --mysql-port=$MYSQL_PORT \
                    --mysql-db=sysbench \
                    --mysql-user=sysbench \
                    --mysql-password=password \
                    --max-time=60 \
                    --max-requests=0 \
                    --num-threads=4 \
                    --oltp-reconnect-mode=random \
                    run
                ;;
            *)
                echo "MySQL usage: $0 $1 {prepare|run}"
                exit 1
                ;;
        esac
        ;;
    postgresql)
        ;;
    *)
        echo "Usage: $0 {redis|memcached|nginx|apache|leveldb|rocksdb|mysql|postgresql}"
        exit 1
        ;;
esac

ssh root@localhost -p 2222 "
date
cd /
time ./gather.sh $1.tar.gz
poweroff
"
