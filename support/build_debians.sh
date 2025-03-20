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
-r,--ros \tROS distro to install [default=noetic|foxy|humble], example: -r noetic
\n
-l,--local_ws \tLocal ROS workspace to use for the build, note: it makes the branch option useless, example: -l ros_ws"

# Default
BRANCH_OPT=devel
ROS_DISTRO_OPT=noetic
UBUNTU_OPT=focal
SERVICE_OPT=""
ROS_WS_OPT=""

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
                ROS_DISTRO_OPT="$2"
                shift
                ;;
        -l|--local_ws)
                ROS_WS_OPT="$2"
                shift
                ;;
        *) print_warn "Option $1 not recognized!"
                echo -e $USAGE
                exit 0;;
        esac
        shift
done

BUILDER_COMPOSE=$SCRIPTPATH/../dockerfiles/dc-debs-builder.yaml

# Validate ros distro option
if [[ "$ROS_DISTRO_OPT" != "noetic" && "$ROS_DISTRO_OPT" != "foxy" && "$ROS_DISTRO_OPT" != "humble" ]]; then
    print_warn "Invalid ROS distro: $ROS_DISTRO_OPT!"
    echo -e "$USAGE"
    exit 1
fi

# Automatically determine distro based on ROS
if [[ ( $ROS_DISTRO_OPT == "noetic" || $ROS_DISTRO_OPT == "foxy" ) ]]
then
        UBUNTU_OPT=focal
elif [[  $ROS_DISTRO_OPT == "humble" ]]
then
        UBUNTU_OPT=jammy
else
        echo -e $USAGE
        exit 0
fi

if [[ "$ROS_WS_OPT" != "" ]]
then
	SERVICE_OPT="wolf-builder-$UBUNTU_OPT-local"
else
	SERVICE_OPT="wolf-builder-$UBUNTU_OPT"
fi

print_info "Using service: $SERVICE_OPT"
print_info "ROS distro: $ROS_DISTRO_OPT"

# Proper usage of docker-compose commands
BRANCH=$BRANCH_OPT ROS_WS=$ROS_WS_OPT ROS_VERSION=$ROS_VERSION_OPT ROS_DISTRO=$ROS_DISTRO_OPT UBUNTU=$UBUNTU_OPT docker-compose -f $BUILDER_COMPOSE down
BRANCH=$BRANCH_OPT ROS_WS=$ROS_WS_OPT ROS_VERSION=$ROS_VERSION_OPT ROS_DISTRO=$ROS_DISTRO_OPT UBUNTU=$UBUNTU_OPT docker-compose -f $BUILDER_COMPOSE up --force-recreate --remove-orphans $SERVICE_OPT
