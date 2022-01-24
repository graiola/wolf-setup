#!/bin/bash

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

set -e

source $SCRIPTPATH/fun.cfg

BUILDER_COMPOSE=$SCRIPTPATH/../dockerfiles/dc-builder.yaml

BRANCH=devel ROS_DISTRO=melodic UBUNTU=bionic docker-compose -f $BUILDER_COMPOSE down
BRANCH=devel ROS_DISTRO=melodic UBUNTU=bionic docker-compose -f $BUILDER_COMPOSE up --force-recreate --remove-orphans

BRANCH=devel ROS_DISTRO=noetic UBUNTU=focal docker-compose -f $BUILDER_COMPOSE down
BRANCH=devel ROS_DISTRO=noetic UBUNTU=focal docker-compose -f $BUILDER_COMPOSE up --force-recreate --remove-orphans
