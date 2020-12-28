#!/bin/bash -e

APP=$1

MOUNTDIR=/mnt/tmpgcovfs
BASEDIR=$(pwd)
LINUXDIR=$BASEDIR/linux-5.9.6
OUTPUTDIR=$BASEDIR/gcov-data
APPDIR=$OUTPUTDIR/$APP

DISK=$BASEDIR/buildroot/output/images/rootfs.ext4

APPTAR=$APP.tar.gz
FINALTAR=$APP-profile.tar.gz

sudo mkdir -p $MOUNTDIR
mkdir -p $OUTPUTDIR
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

# Create json output for each source file
cd $LINUXDIR
for FILE in "${FILES[@]}"; do
    FILE="${FILE%%.*}"
    FILEDIR="${FILE%/*}"
    SOURCE="${FILE##*/}.c"
    OUTPUTGZ="$SOURCE.gcov.json.gz"

    cd "$LINUXDIR/$FILEDIR"
    gcov -b -i -o $APPDIR/$FILEDIR $SOURCE > /dev/null
    mv $OUTPUTGZ $APPDIR/$FILEDIR
    cd $APPDIR/$FILEDIR
    gunzip $OUTPUTGZ
    cd $LINUXDIR
done

cd $OUTPUTDIR
tar -cvf $FINALTAR $APP

