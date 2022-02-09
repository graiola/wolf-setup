#!/bin/bash

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

set -e

source $SCRIPTPATH/fun.cfg

USAGE="Usage: \n build_docker [OPTIONS...] 
\n\n
Help Options:
\n 
-h,--help \tShow help options
\n\n
Application Options:
\n 
-b,--build \tBuild options [base|app|all], example: -b all"

# Default
BUILD_OPT=all
BASE_COMPOSE=$SCRIPTPATH/../dockerfiles/dc-base.yaml
APP_COMPOSE=$SCRIPTPATH/../dockerfiles/dc-app.yaml

if [[ ( $1 == "--help") ||  $1 == "-h" ]] 
then 
	echo -e $USAGE
	exit 0
fi

while [ -n "$1" ]; do # while loop starts
	case "$1" in
         -b|--build)
    		BUILD_OPT="$2"
		shift
		;;
	*) echo "Option $1 not recognized!" 
		echo -e $USAGE
		exit 0;;
	esac
	shift
done

# Checks
if [[ ( $BUILD_OPT == "base") ||  ( $BUILD_OPT == "app") ||  ( $BUILD_OPT == "all")]] 
then 
	echo "Selected build option: $BUILD_OPT"
else
	echo "Wrong build option!"
	echo -e $USAGE
	exit 0
fi

if [[ ( $BUILD_OPT == "base") || ( $BUILD_OPT == "all") ]]
then 
	DOCKERFILE_PATH=$SCRIPTPATH/../dockerfiles/base CONTEXT_PATH=$SCRIPTPATH/.. docker-compose -f $BASE_COMPOSE build --no-cache
fi
if [[ ( $BUILD_OPT == "app") || ( $BUILD_OPT == "all") ]]
then 
	DOCKERFILE_PATH=$SCRIPTPATH/../dockerfiles/app CONTEXT_PATH=$SCRIPTPATH/.. docker-compose -f $APP_COMPOSE build --no-cache
	docker tag wolf-app:bionic serger87/wolf-app:bionic
	docker tag wolf-app:focal serger87/wolf-app:focal
	docker push serger87/wolf-app:bionic
	docker push serger87/wolf-app:focal
fi


