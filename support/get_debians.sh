#!/bin/bash

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

source $SCRIPTPATH/fun.cfg

# Clean
rm -rf $SCRIPTPATH/../debs/*

#Download
wget -P $SCRIPTPATH/../debs https://www.dropbox.com/sh/njzikm4yk61w2r8/AABcoJi5BDrRb8Lhc_ftnH1ca?dl=0 --content-disposition
unzip $SCRIPTPATH/../debs/wolf.zip -d $SCRIPTPATH/../debs/

exit 0
