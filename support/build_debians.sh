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
-b,--branch \tBranch to build, example: -b devel
\n
-r,--ros \tRos version to build, example: -r 1|2"

# Default
BRANCH_OPT=devel
ROS_VERSION_OPT=1
ROS_DISTRO_OPT=noetic
UBUNTU_OPT=focal
SERVICE_OPT=""

if [[ ( $1 == "--help") ||  $1 == "-h" ]]
then
        echo -e $USAGE
        exit 0
fi

while [ -n "$1" ]; do # while loop starts
        case "$1" in
        -b|--branch)
                BRANCH_OPT="$2"
                shift
                ;;
        -r|--ros)
                ROS_VERSION_OPT="$2"
                shift
                ;;
        *) print_warn "Option $1 not recognized!"
                echo -e $USAGE
                exit 0;;
        esac
        shift
done

BUILDER_COMPOSE=$SCRIPTPATH/../dockerfiles/dc-debs-builder.yaml

# Automatically determine service based on ROS version
if [[ ( $ROS_VERSION_OPT == 1 ) ]]
then
        print_info "Build debians for ROS1"
        ROS_DISTRO_OPT=noetic
        UBUNTU_OPT=focal
        SERVICE_OPT="wolf-builder-focal"
elif [[ ( $ROS_VERSION_OPT == 2 ) ]]
then
        print_info "Build debians for ROS2"
        ROS_DISTRO_OPT=humble
        UBUNTU_OPT=jammy
        SERVICE_OPT="wolf-builder-jammy"
else
        echo -e $USAGE
        exit 0
fi

print_info "Using service: $SERVICE_OPT"

# Proper usage of docker-compose commands
BRANCH=$BRANCH_OPT ROS_VERSION=$ROS_VERSION_OPT ROS_DISTRO=$ROS_DISTRO_OPT UBUNTU=$UBUNTU_OPT docker-compose -f $BUILDER_COMPOSE down
BRANCH=$BRANCH_OPT ROS_VERSION=$ROS_VERSION_OPT ROS_DISTRO=$ROS_DISTRO_OPT UBUNTU=$UBUNTU_OPT docker-compose -f $BUILDER_COMPOSE up --force-recreate --remove-orphans $SERVICE_OPT
