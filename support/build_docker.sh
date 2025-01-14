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
-b,--build \tBuild options [base|app|default=all], example: -b all
\n
-d,--distro \tDistro to build [bionic|default=focal|jammy], example: -d focal
\n
-r,--ros \tROS distro to install [default=noetic|foxy|humble], example: -r noetic
\n
--no-cache \tBuild the images without using cache"

# Default options
BUILD_OPT="all"
DISTRO_OPT="focal"
ROS_DISTRO_OPT="noetic"
NO_CACHE_FLAG=""
DOCKER_COMPOSE_FILE="$SCRIPTPATH/../dockerfiles/dc-image-builder.yaml"

if [[ ( $1 == "--help") ||  $1 == "-h" ]]; then
    echo -e "$USAGE"
    exit 0
fi

# Parse options
while [[ -n "$1" ]]; do
    case "$1" in
        -b|--build)
            BUILD_OPT="$2"
            shift
            ;;
        -d|--distro)
            DISTRO_OPT="$2"
            shift
            ;;
        -r|--ros)
            ROS_DISTRO_OPT="$2"
            shift
            ;;
        --no-cache)
            NO_CACHE_FLAG="--no-cache"
            ;;
        *)
            print_warn "Option $1 not recognized!"
            echo -e "$USAGE"
            exit 1
            ;;
    esac
    shift
done

# Validate build option
if [[ "$BUILD_OPT" != "base" && "$BUILD_OPT" != "app" && "$BUILD_OPT" != "all" ]]; then
    print_warn "Invalid build option: $BUILD_OPT!"
    echo -e "$USAGE"
    exit 1
fi

# Validate distro option
if [[ "$DISTRO_OPT" != "bionic" && "$DISTRO_OPT" != "focal" && "$DISTRO_OPT" != "jammy" ]]; then
    print_warn "Invalid distro: $DISTRO_OPT!"
    echo -e "$USAGE"
    exit 1
fi

# Validate ros distro option
if [[ "$ROS_DISTRO_OPT" != "noetic" && "$ROS_DISTRO_OPT" != "foxy" && "$ROS_DISTRO_OPT" != "humble" ]]; then
    print_warn "Invalid ROS distro: $ROS_DISTRO_OPT!"
    echo -e "$USAGE"
    exit 1
fi

print_info "Selected build option: $BUILD_OPT"
print_info "Selected distro: $DISTRO_OPT"
print_info "Selected ROS distro: $ROS_DISTRO_OPT"

# Function to build base image
build_base() {
    print_info "Building base image for $DISTRO_OPT with $ROS_DISTRO_OPT..."
    SERVICE_NAME="wolf-base-$DISTRO_OPT"
    DOCKERFILE_PATH="$SCRIPTPATH/../dockerfiles/base" CONTEXT_PATH="$SCRIPTPATH/.." ROS_DISTRO="$ROS_DISTRO_OPT" \
        docker-compose -f "$DOCKER_COMPOSE_FILE" build $NO_CACHE_FLAG "$SERVICE_NAME"
}

# Function to build app image
build_app() {
    print_info "Building app image for $DISTRO_OPT with $ROS_DISTRO_OPT..."
    SERVICE_NAME="wolf-app-$DISTRO_OPT"
    DOCKERFILE_PATH="$SCRIPTPATH/../dockerfiles/app" CONTEXT_PATH="$SCRIPTPATH/.." ROS_DISTRO="$ROS_DISTRO_OPT" \
        docker-compose -f "$DOCKER_COMPOSE_FILE" build $NO_CACHE_FLAG "$SERVICE_NAME"

    IMAGE_TAG="serger87/wolf-app:$DISTRO_OPT"
    print_info "Tagging and pushing the app image as $IMAGE_TAG"
    docker tag "wolf-app:$DISTRO_OPT" "$IMAGE_TAG"
    docker push "$IMAGE_TAG"
}

# Build services based on the selected option
if [[ "$BUILD_OPT" == "base" || "$BUILD_OPT" == "all" ]]; then
    build_base
fi

if [[ "$BUILD_OPT" == "app" || "$BUILD_OPT" == "all" ]]; then
    build_app
fi

print_info "Build process completed."
