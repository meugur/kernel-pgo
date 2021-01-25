#!/bin/bash -e

APP=$1

MOUNTDIR=/mnt/tmpgcovfs
BASEDIR=$(pwd)
GCOV_BIN=/usr/bin/gcov-9
LINUXDIR=$BASEDIR/linux-5.3
OUTPUTDIR=$BASEDIR/gcov-data-5-3
APPDIR=$OUTPUTDIR/$APP

DISK=$BASEDIR/images/ubuntu_base_20_04_1_kernel_5_3.img

APPTAR=$APP.tar.gz
FINALTAR=$APP-profile.tar.gz

sudo mkdir -p $MOUNTDIR
mkdir -p $APPDIR
rm -rf $APPDIR/* # Clear application directory

# Copy data to output directory
sudo mount -t ext4 $DISK $MOUNTDIR
sudo cp $MOUNTDIR/$APPTAR $OUTPUTDIR
sudo umount $MOUNTDIR

sudo chmod 664 $OUTPUTDIR/$APPTAR
tar xfz $OUTPUTDIR/$APPTAR -C $OUTPUTDIR

mv $OUTPUTDIR/sys/kernel/debug/gcov$LINUXDIR/* $APPDIR
rm -rf $OUTPUTDIR/sys

# Get all files that have data
shopt -s globstar
cd $APPDIR
FILES=(**/*.gcda)

# Create json/gcov output for each source file
cd $LINUXDIR
for FILE in "${FILES[@]}"; do
    FILE="${FILE%%.*}"
    FILEDIR="${FILE%/*}"
    SOURCE="${FILE##*/}"

    OUTPUTC="$SOURCE.c.gcov"
    OUTPUTH="$SOURCE.h.gcov"
    OUTPUTGZ="$SOURCE.gcov.json.gz"

    # Create the .gcov file
    $GCOV_BIN -a -b -f -m -p -o $APPDIR/$FILEDIR $SOURCE > /dev/null

    # Create and unzip the json summary
    $GCOV_BIN -a -b -i -o $APPDIR/$FILEDIR $SOURCE > /dev/null
    mv $OUTPUTGZ $APPDIR/$FILEDIR
    cd $APPDIR/$FILEDIR
    gunzip $OUTPUTGZ

    cd $LINUXDIR
done

cd $LINUXDIR
GCOV_FILES=(*.gcov)

# Move all .gcov files to their respective directories
for FILE in "${GCOV_FILES[@]}"; do
    FILE_N="${FILE//\#//}"
    FILEDIR="${FILE_N%/*}"
    SOURCE="${FILE_N##*/}"
    
    mkdir -p $APPDIR/$FILEDIR
    mv $FILE $APPDIR/$FILE_N 
done


cd $OUTPUTDIR
tar --exclude="*.gcno" --exclude="*.gcda" -cvf $FINALTAR $APP

