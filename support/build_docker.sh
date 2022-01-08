#!/bin/bash

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

set -e

source $SCRIPTPATH/fun.cfg

UBUNTU=$(lsb_release -cs)

docker build --tag wolf:$UBUNTU -f $SCRIPTPATH/../dockerfile/Dockerfile ..

docker tag wolf:$UBUNTU serger87/wolf:$UBUNTU

docker push serger87/wolf:$UBUNTU
