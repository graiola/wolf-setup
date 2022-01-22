#!/bin/bash

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

set -e

source $SCRIPTPATH/fun.cfg

BUILDER_COMPOSE=$SCRIPTPATH/../dockerfiles/dc-builder.yaml

#docker-compose -f $BUILDER_COMPOSE down
#UBUNTU=bionic ROS_DISTRO=melodic docker-compose -f $BUILDER_COMPOSE up

docker-compose -f $BUILDER_COMPOSE down
UBUNTU=focal ROS_DISTRO=noetic docker-compose -f $BUILDER_COMPOSE up
