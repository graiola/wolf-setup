#!/usr/bin/env bash

# Get this script's path
pushd "$(dirname "$0")" > /dev/null
SCRIPTPATH="$(pwd)"
popd > /dev/null

set -e

source "$SCRIPTPATH/support/fun.cfg"

USAGE="Usage: run_docker [OPTIONS...]
\n
Help Options:
\n
  -h, --help        Show help options
\n
Application Options:
\n
  -r, --robot       Robot model [spot|go1]
  -d, --device      Input device [ps3|xbox|twist|keyboard]
  -w, --world       World [empty|ruins|pyramid|ramps|stairs|office]
  -g, --gui         Launch rviz
  -n, --net         Use host networking
  -l, --local       Run local workspace, e.g. -l ros_ws
  -i, --image       Image base name [wolf-app|wolf-base]
  -t, --tag         Tag name (Ubuntu codename) [focal|jammy|noble]"

# Defaults
ROBOT_MODEL=spot
DEVICE=keyboard
WORLD_NAME=empty
GUI=false
RUN_LOCAL_WS=false
DOCKER_NET=bridge
ROS_WS=
IMAGE_NAME="wolf-app"
IMAGE_TAG="focal"
CONTAINER_NAME="wolf-container"
DOCKER_REGISTRY=serger87

# Functions
function run_local_ros_workspace() {
    docker run --user root:root --hostname "$HOSTNAME" --ipc=host --net=$DOCKER_NET --device=/dev/dri:/dev/dri --privileged \
    -e QT_X11_NO_MITSHM=1 -e GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:/opt/ros/$2/share/wolf_gazebo_resources/models/ \
    -e SHELL -e DISPLAY -e DOCKER=1 --name "$CONTAINER_NAME" --gpus all --device=/dev/ttyUSB0 \
    --workdir="/home/$USER" \
    -v "/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    -v "$HOME/$1/src:$HOME/$1/src" \
    -v "/etc/group:/etc/group:rw" \
    -v "/etc/passwd:/etc/passwd:rw" \
    -v "/etc/shadow:/etc/shadow:rw" \
    -v "/etc/sudoers:/etc/sudoers:rw" \
    -v "/etc/sudoers.d:/etc/sudoers.d:rw" \
    -v "$HOME/.ros:$HOME/.ros" \
    -v "$HOME/.gazebo:$HOME/.gazebo" \
    -v "$HOME/.ignition:$HOME/.ignition" \
    -v "$HOME/.rviz:$HOME/.rviz" \
    -it "$FULL_IMAGE_NAME" $SHELL -c "export HOME=$HOME; cd $HOME; source /opt/ros/$2/setup.bash; bash"
}

function run_docker_ros_workspace() {
    docker run --user root:root --hostname "$HOSTNAME" --ipc=host --net=$DOCKER_NET --device=/dev/dri:/dev/dri --privileged \
    -e QT_X11_NO_MITSHM=1 -e GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:/opt/ros/$1/share/wolf_gazebo_resources/models/ \
    -e SHELL -e DISPLAY -e DOCKER=1 --name "$CONTAINER_NAME" --gpus all --device=/dev/ttyUSB0 \
    -v "/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    -it "$FULL_IMAGE_NAME" $SHELL -c "source /opt/ros/$1/setup.bash; $CMD robot_model:=$ROBOT_MODEL world_name:=$WORLD_NAME full_gui:=$GUI input_device:=$DEVICE"
}

# Parse args
while [[ -n "$1" ]]; do
    case "$1" in
        -r|--robot)   ROBOT_MODEL="$2"; shift ;;
        -d|--device)  DEVICE="$2"; shift ;;
        -w|--world)   WORLD_NAME="$2"; shift ;;
        -g|--gui)     GUI=true ;;
        -n|--net)     DOCKER_NET=host ;;
        -l|--local)   ROS_WS="$2"; RUN_LOCAL_WS=true; shift ;;
        -i|--image)   IMAGE_NAME="$2"; shift ;;
        -t|--tag)     IMAGE_TAG="$2"; shift ;;
        -h|--help)    echo -e "$USAGE"; exit 0 ;;
        *) print_warn "Unknown option: $1"; echo -e "$USAGE"; exit 1 ;;
    esac
    shift
done

# Validate options
valid_robots=("spot" "go1")
valid_devices=("ps3" "xbox" "twist" "keyboard")
valid_worlds=("empty" "ruins" "pyramid" "ramps" "stairs" "office")
valid_tags=("focal" "jammy" "noble")

if [[ ! " ${valid_robots[*]} " =~ " $ROBOT_MODEL " ]]; then
    print_warn "Invalid robot model!"; echo -e "$USAGE"; exit 1
fi

if [[ ! " ${valid_devices[*]} " =~ " $DEVICE " ]]; then
    print_warn "Invalid input device!"; echo -e "$USAGE"; exit 1
fi

if [[ ! " ${valid_worlds[*]} " =~ " $WORLD_NAME " ]]; then
    print_warn "Invalid world name!"; echo -e "$USAGE"; exit 1
fi

if [[ ! " ${valid_tags[*]} " =~ " $IMAGE_TAG " ]]; then
    print_warn "Invalid image tag!"; echo -e "$USAGE"; exit 1
fi

# Determine ROS distro & version
case "$IMAGE_TAG" in
    focal)
        ROS_DISTRO=noetic
        ROS_VERSION=1
        CMD='roslaunch wolf_controller wolf_controller_bringup.launch'
        ;;
    jammy)
        ROS_DISTRO=humble
        ROS_VERSION=2
        CMD='ros2 launch wolf_controller wolf_controller_bringup.launch.xml'
        ;;
    noble)
        ROS_DISTRO=one
        ROS_VERSION=1
        CMD='roslaunch wolf_controller wolf_controller_bringup.launch'
        ;;
    *)
        print_warn "Unsupported image tag for ROS setup"; exit 1
        ;;
esac

# Compose full image name using new convention
FULL_IMAGE_NAME="${IMAGE_NAME}-${ROS_DISTRO}:${IMAGE_TAG}"

# Ensure Docker is running
if ! sudo systemctl is-active --quiet docker; then
    echo "Docker inactive. Starting docker..."
    sudo systemctl restart docker
fi

# Pull if missing
if ! docker image inspect "$FULL_IMAGE_NAME" > /dev/null 2>&1; then
    print_warn "Image $FULL_IMAGE_NAME not found. Pulling from registry..."
    docker pull "$DOCKER_REGISTRY/$FULL_IMAGE_NAME"
    docker tag "$DOCKER_REGISTRY/$FULL_IMAGE_NAME" "$FULL_IMAGE_NAME"
fi

# Cleanup old container
docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1 || true

# Allow GUI access
xhost +local:docker

# Run the container
if $RUN_LOCAL_WS; then
    print_info "Running with local workspace: $ROS_WS"
    run_local_ros_workspace "$ROS_WS" "$ROS_DISTRO"
else
    run_docker_ros_workspace "$ROS_DISTRO"
fi
