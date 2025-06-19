#!/bin/bash

# Get this script's path
pushd "$(dirname $0)" > /dev/null
SCRIPTPATH="$(pwd)"
popd > /dev/null

set -e

source "$SCRIPTPATH/fun.cfg"

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
-r,--ros \tROS distro to install [noetic|foxy|humble|one], example: -r noetic
\n
-l,--local_ws \tLocal ROS workspace to use for the build, note: it makes the branch option useless, example: -l ros_ws"

# Defaults
BRANCH_OPT=devel
ROS_DISTRO_OPT=noetic
UBUNTU_OPT=focal
ROS_VERSION_OPT=""
SERVICE_OPT=""
ROS_WS_OPT=""

# Parse args
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo -e "$USAGE"
    exit 0
fi

while [ -n "$1" ]; do
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
        *)
            print_warn "Option $1 not recognized!"
            echo -e "$USAGE"
            exit 1
            ;;
    esac
    shift
done

BUILDER_COMPOSE="$SCRIPTPATH/../dockerfiles/dc-debs-builder.yaml"

# Determine UBUNTU and ROS version from ROS_DISTRO
case "$ROS_DISTRO_OPT" in
    noetic)
        UBUNTU_OPT=focal
        ROS_VERSION_OPT=1
        ;;
    foxy)
        UBUNTU_OPT=focal
        ROS_VERSION_OPT=2
        ;;
    humble)
        UBUNTU_OPT=jammy
        ROS_VERSION_OPT=2
        ;;
    one)
        UBUNTU_OPT=noble
        ROS_VERSION_OPT=2
        ;;
    *)
        print_warn "Invalid ROS distro: $ROS_DISTRO_OPT!"
        echo -e "$USAGE"
        exit 1
        ;;
esac

# Determine Compose service
if [[ -n "$ROS_WS_OPT" ]]; then
    SERVICE_OPT="wolf-builder-$UBUNTU_OPT-local"
else
    SERVICE_OPT="wolf-builder-$UBUNTU_OPT"
fi

print_info "Using service: $SERVICE_OPT"
print_info "ROS distro: $ROS_DISTRO_OPT"

# Run Compose
BRANCH=$BRANCH_OPT \
ROS_WS=$ROS_WS_OPT \
ROS_VERSION=$ROS_VERSION_OPT \
ROS_DISTRO=$ROS_DISTRO_OPT \
UBUNTU=$UBUNTU_OPT \
docker-compose -f "$BUILDER_COMPOSE" down

BRANCH=$BRANCH_OPT \
ROS_WS=$ROS_WS_OPT \
ROS_VERSION=$ROS_VERSION_OPT \
ROS_DISTRO=$ROS_DISTRO_OPT \
UBUNTU=$UBUNTU_OPT \
docker-compose -f "$BUILDER_COMPOSE" up --force-recreate --remove-orphans "$SERVICE_OPT"

