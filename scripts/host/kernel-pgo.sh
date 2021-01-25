#!/bin/bash

set -e

APP=${1:-}

if [[ -z $APP ]]; then
    echo "Usage: $0 {redis|memcached|nginx|apache|leveldb|rocksdb|mysql|postgresql}"
    exit 1
fi

BUILD_DIR=/home/meugur/dev/eecs/eecs582/kernel-pgo/linux-5.3
GCOV_DATA=/home/meugur/dev/eecs/eecs582/kernel-pgo/gcov-data-5-3/$APP

make_path() {
    echo $1 | sed -r 's/[/]+/#/g'
}

echo "Copying profile to build directory..."
FILES=$(find $GCOV_DATA -depth -type f -name "*.gcda")
for FILE in ${FILES[@]}; do
    FLAT=$(make_path $FILE)
    HEAD=${FLAT##*$APP}
    NEW="$(make_path $BUILD_DIR)$HEAD"
    cp $FILE $GCOV_DATA/$NEW
done
echo "Finished copying!"

cd linux-5.3

echo "Cleaning build..."
make clean
echo "Finished cleaning!"

echo "Compiling kernel..."

# FLAGS
# -Wno-missing-profile
# V=1
make CC=/usr/bin/gcc-9 KCFLAGS="-fprofile-use=$GCOV_DATA -fprofile-correction -Wno-coverage-mismatch -Wno-error=coverage-mismatch" -j4 2>&1 | tee compile_$APP.log
SUCCESS=$?

if [[ $SUCCESS -eq 1 ]]; then
    echo "Error!"
else
    echo "Finished!"
fi

find . -name "*.gcda" -exec rm {} \;
