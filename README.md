# kernel-pgo
Profile creation for Linux kernel profile-guided optimizations.

This project uses QEMU for system emulation to run benchmarks for specific applications.
These applications include Apache, Nginx, Redis, Memcached, Leveldb, Rocksdb, MySQL, and PostgreSQL.

GCOV data for these benchmarks is then collected to use for profile data creation. For more info:

https://www.kernel.org/doc/html/latest/dev-tools/gcov.html

https://www.man7.org/linux/man-pages/man1/gcov.1.html

1. [Setup Linux kernel](#setup)

# Setup Linux kernel
## Download
Download a Linux kernel 5.x version. For example:
```
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.9.6.tar.xz
xz -cd linux-5.9.6.tar.xz | tar xvf -
```
Make sure you have the requirements to compile a Linux kernel

https://www.kernel.org/doc/html/latest/process/changes.html

## Configuration
```
cd linux-5.9.6
make menuconfig
```
Set the following:
```
General architecture-dependent options --> GCOV-based kernel profiling --> Enable gcov-based kernel profiling
General architecture-dependent options --> GCOV-based kernel profiling --> Profile entire Kernel
Device Drivers --> Network device support --> Ethernet driver support --> Intel(R) PRO/1000 Gigabit Ethernet support
```

Save the config and double check that these variables are set in the `.config` file:
```
CONFIG_PVH=y
CONFIG_DEBUG_FS=y
CONFIG_GCOV_KERNEL=y
CONFIG_GCOV_PROFILE_ALL=y
CONFIG_E1000=y
```
## Compilation
In the kernel directory:
```
make -j8
```
# Setup Buildroot
This project uses Buildroot to create a root file system with specific utilities.
## Download
```
git clone git@github.com:buildroot/buildroot.git
```

## Configuration
```
cd buildroot
make menuconfig
```
Set the following (some of the target packages are for debugging):
```
Target options --> Target architecture --> x86_64
Toolchain --> C library --> glibc
Toolchain --> Install glibc utilities
Toolchain --> Enable C++ support
Target packages --> Show packages that are also provided by busybox
Target packages --> Compressors and decompressors --> bzip2, zstd
Target packages --> Libraries --> Compression and decompression --> lz4, snappy, zlib support
Target packages --> Libraries --> Database --> leveldb, postgresql, redis, rocksdb
Target packages --> Libraries --> Database --> mysql support, oracle mysql server
Target packages --> Libraries --> Other --> gflags
Target packages --> Networking applications --> apache, memcached, nginx
Target packages --> Networking applications --> dhcp, dhcp server/client, dhcpcd
Target packages --> Networking applications --> ifupdown scripts, net-tools, netcat
Target packages --> Networking applications --> openssh, openssh server, openssh key utilities
Target packages --> System tools --> tar
Target packages --> Text editors and viewers --> vim
System configuration --> /bin/sh --> bash
System configuration --> Root filesystem overlay directories --> $REPO_PATH/overlay
Filesystem images --> ext2/3/4 root filesystem
Filesystem images --> ext2/3/4 root filesystem --> ext2/3/4 variant --> ext4
Filesystem images --> exact size --> 10G # This will change based on the benchmarks
```
## Compilation
In the buildroot directory:
```
make -j8
```

# Collecting profile data
## Run QEMU
Run the emulated system from the repository root:
```
qemu-system-x86_64 \
    -kernel $(pwd)/linux-5.9.6/vmlinux \
    -boot c \
    -m 512 \
    -hda $(pwd)/buildroot/output/images/rootfs.ext4 \
    -append 'root=/dev/sda rw console=ttyS0 nokaslr' \
    -display none \
    -serial mon:stdio \
    -enable-kvm \
    -cpu host \
    -nic user,hostfwd=tcp:127.0.0.1:7369-:7369,hostfwd=tcp:127.0.0.1:1080-:80,hostfwd=tcp::2222-:22
```
or
```
./run-emulator.sh
```
Login to the system with username `root`, and ensure that no errors arise.

### Debugging
If there is an issue, `poweroff` the system. If you can't do that, then
```
ps aux | grep qemu
kill -9 pid_of_qemu
```
Reboot the system afterwards.

Also, make sure to test network availability:
```
ping google.com
```

## Run benchmarks
Make sure that you can have dependences for the benchmark you want to run on the host.
Specify the application that you would like to collect data for:
```
./benchmark.sh redis
```
For MySQL/PostgreSQL:
```
./benchmark.sh mysql prepare
./benchmark.sh mysql run

./benchmark.sh postgresql prepare
./benchmark.sh postgresql run
```
This script will shutdown the guest system on success, so make sure to restart it between runs.

The benchmark may fail, in which case, you should try it again.
If the issue persists, then there is a bug somewhere.

If the benchmark is successful, run the following to get profile data:
```
./collect-gcov.sh redis
```
This will mount the rootfs to the host system and copy the data from the guest to the host.
There will be a  `gcov-data` directory with the gcov data in `.tar.gz` format.

### Apache/Nginx
Install Apache Bench

Ubuntu:
```
apt install apache2-utils
```
### Redis
Install `redis-benchmark` (built into redis)

Ubuntu:
```
apt install redis-server
```
When running the benchmark script for redis, you will need to `Ctrl+c` after the
server starts on the guest to get the benchmark to actually run.

### Memcached
Install `mc-benchmark`
```
git clone git@github.com:antirez/mc-benchmark.git
cd mc-benchmark
make
```
When running the benchmark script for memcached, you will need to `Ctrl+c` after the
server starts on the guest to get the benchmark to actually run.

### MySQL
The buildroot MySQL installation is version 5.1.73. In order to use sysbench, for
this version, install sysbench version 0.4.12. This also requires installing the
proper MySQL version 5.1.73 libraries. For more info:

https://wiki.mikejung.biz/Sysbench

Install MySQL 5.1.73
```
wget https://dev.mysql.com/get/Downloads/MySQL-5.1/mysql-5.1.73.tar.gz
tar xzvf mysql-5.1.73.tar.gz

./install-mysql.sh

cd mysql-5.1.73
make install
```
Install sysbench 0.4.12
```
wget https://downloads.mysql.com/source/sysbench-0.4.12.16.tar.gz
tar xzvf sysbench-0.4.12.16.tar.gz
cd sysbench-0.4.12.16
./autogen.sh
./configure
make
```
When running the benchmark script for mysql, you will need to `Ctrl+c` after the
server starts on the guest to get the benchmark to actually run.

### PostgreSQL
Install latest sysbench

Ubuntu
```
sudo apt install sysbench libpq-dev
```

### Leveldb
Build leveldb to get the `db_bench` tool on the emulated machine:
```
git clone --recurse-submodules git@github.com:google/leveldb.git
./build-leveldb.sh

# Re-build buildroot to get the benchmark
cd buildroot
make -j8
```
### Rocksdb
Build rocksdb to get the `db_bench` tool on the emulated machine:

Get the required libraries (https://github.com/facebook/rocksdb/blob/master/INSTALL.md):

Ubuntu:
```
sudo apt install libgflags-dev libsnappy-dev zlib1g-dev libbz2-dev liblz4-dev libzstd-dev
```

Build rocksdb to get the `db_bench` tool on the emulated machine:
```
git clone git@github.com:facebook/rocksdb.git
./build-rocksdb.sh

# Re-build buildroot to get the benchmark
cd buildroot
make -j8
```
