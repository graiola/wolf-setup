#!/bin/bash

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

set -e

source $SCRIPTPATH/fun.cfg

USAGE="Usage: \n build_debians [OPTIONS...]
\n\n
Help Options:
\n 
-h,--help \tShow help options
\n\n
Application Options:
\n 
-b,--branch \tBranch to build, example: -b devel"

# Default
BRANCH=devel

if [[ ( $1 == "--help") ||  $1 == "-h" ]] 
then 
	echo -e $USAGE
	exit 0
fi

while [ -n "$1" ]; do # while loop starts
	case "$1" in
	-b|--branch)
		BRANCH="$2"
		shift
		;;
	*) echo "Option $1 not recognized!" 
		echo -e $USAGE
		exit 0;;
	esac
	shift
done


BUILDER_COMPOSE=$SCRIPTPATH/../dockerfiles/dc-builder.yaml

BRANCH=$BRANCH ROS_DISTRO=melodic UBUNTU=bionic docker-compose -f $BUILDER_COMPOSE down
BRANCH=$BRANCH ROS_DISTRO=melodic UBUNTU=bionic docker-compose -f $BUILDER_COMPOSE up --force-recreate --remove-orphans

BRANCH=$BRANCH ROS_DISTRO=noetic UBUNTU=focal docker-compose -f $BUILDER_COMPOSE down
BRANCH=$BRANCH ROS_DISTRO=noetic UBUNTU=focal docker-compose -f $BUILDER_COMPOSE up --force-recreate --remove-orphans
