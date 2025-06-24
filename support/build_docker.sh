#!/bin/bash

set -e

# Get this script's path
SCRIPTPATH="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPTPATH/fun.cfg"

USAGE="Usage: build_docker [OPTIONS...]
Options:
  -h, --help           Show help options
  -i, --image          Image(s) to build [base|app|all] (default: all)
  -d, --distro         Distro to build [bionic|focal|jammy|noble] (default: jammy)
  -r, --ros            ROS distro [noetic|one|foxy|humble] (default: one)
  -b, --branch         Branch to install in the app image (default: devel)
  -p, --push           Push the built image(s)
      --no-cache       Build without using cache"

# Defaults
BUILD_OPT="all"
DISTRO_OPT="jammy"
ROS_DISTRO_OPT="one"
BRANCH_OPT="devel"
PUSH_OPT="no"
NO_CACHE_FLAG=""
DOCKER_COMPOSE_FILE="$SCRIPTPATH/../dockerfiles/dc-image-builder.yaml"

# Help
[[ "$1" == "-h" || "$1" == "--help" ]] && echo -e "$USAGE" && exit 0

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--image)  BUILD_OPT="$2"; shift ;;
        -d|--distro) DISTRO_OPT="$2"; shift ;;
        -r|--ros)    ROS_DISTRO_OPT="$2"; shift ;;
        -b|--branch) BRANCH_OPT="$2"; shift ;;
        -p|--push)   PUSH_OPT="yes" ;;
        --no-cache)  NO_CACHE_FLAG="--no-cache" ;;
        *) print_warn "Unknown option: $1"; echo -e "$USAGE"; exit 1 ;;
    esac
    shift
done

# Validation
[[ ! "$BUILD_OPT" =~ ^(base|app|all)$ ]] && print_warn "Invalid image: $BUILD_OPT" && echo -e "$USAGE" && exit 1
[[ ! "$DISTRO_OPT" =~ ^(bionic|focal|jammy|noble)$ ]] && print_warn "Invalid distro: $DISTRO_OPT" && echo -e "$USAGE" && exit 1
[[ ! "$ROS_DISTRO_OPT" =~ ^(noetic|one|foxy|humble)$ ]] && print_warn "Invalid ROS distro: $ROS_DISTRO_OPT" && echo -e "$USAGE" && exit 1

print_info "Build: $BUILD_OPT | Distro: $DISTRO_OPT | ROS: $ROS_DISTRO_OPT | Branch: $BRANCH_OPT | Push: $PUSH_OPT"

# Cleanup
sudo rm -rf $SCRIPTPATH/../debs

# Build helper
build_image() {
    local TYPE="$1"
    local SERVICE="wolf-${TYPE}-${DISTRO_OPT}"
    local IMAGE_NAME="wolf-${TYPE}-${ROS_DISTRO_OPT}"
    local TAG="${IMAGE_NAME}:${DISTRO_OPT}"
    local FULL_TAG="serger87/${TAG}"
    local DOCKERFILE_PATH="$SCRIPTPATH/../dockerfiles/$TYPE"

    # Determine ROS version (1 or 2)
    if [[ "$ROS_DISTRO_OPT" == "noetic" || "$ROS_DISTRO_OPT" == "one" ]]; then
        ROS_VERSION="1"
    else
        ROS_VERSION="2"
    fi

    print_info "Building $TYPE image..."
    DOCKERFILE_PATH="$DOCKERFILE_PATH" CONTEXT_PATH="$SCRIPTPATH/.." \
    ROS_DISTRO="$ROS_DISTRO_OPT" BRANCH="$BRANCH_OPT" ROS_VERSION="$ROS_VERSION" \
    docker-compose -f "$DOCKER_COMPOSE_FILE" build $NO_CACHE_FLAG "$SERVICE"

    if [[ "$PUSH_OPT" == "yes" ]]; then
        print_info "Tagging and pushing $TYPE image as $FULL_TAG"
        docker tag "$IMAGE_NAME:$DISTRO_OPT" "$FULL_TAG"
        docker push "$FULL_TAG"
    else
        print_info "Skipping push for $TYPE image"
    fi
}

# Build targets
[[ "$BUILD_OPT" == "base" || "$BUILD_OPT" == "all" ]] && build_image "base"
[[ "$BUILD_OPT" == "app"  || "$BUILD_OPT" == "all" ]] && build_image "app"

print_info "Build process completed."

