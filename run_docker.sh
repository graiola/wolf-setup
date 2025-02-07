#!/usr/bin/env bash

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

set -e

source $SCRIPTPATH/support/fun.cfg

# Help/Usage text with all options
USAGE="Usage: run_docker [OPTIONS...]
\n
Help Options:
\n
  -h, --help        Show help options
\n
Application Options:
\n
  -r, --robot       Robot model [spot|go1], example: -r spot
\n
  -d, --device      Input device type [ps3|xbox|twist|keyboard], example: -d ps3
\n
  -w, --world       World name [empty|ruins|pyramid|ramps|stairs|office], example: -w ruins
\n
  -g, --gui         Launch rviz
\n
  -n, --net         Launch docker with shared network, useful to visualize the ROS topics on the host machine
\n
  -l, --local       Run a local ROS workspace inside the container [workspace], example: -l ros_ws
\n
  -i, --image       Specify the Docker image name [wolf-base|wolf-app], example: -i wolf-app
\n
  -t, --tag         Specify the Docker image tag [focal|jammy], example: -t focal
"

# Default
ROBOT_NAME=
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

function run_local_ros_workspace()
{
        docker run --user root:root --hostname $HOSTNAME --ipc=host --net=$DOCKER_NET --device=/dev/dri:/dev/dri --privileged -e "QT_X11_NO_MITSHM=1" -e GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:/opt/ros/$2/share/wolf_gazebo_resources/models/ -e SHELL -e DISPLAY -e DOCKER=1 --name $CONTAINER_NAME \
        --gpus all \
        --device=/dev/ttyUSB0 \
        --workdir="/home/$USER" \
        --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
        --volume="$HOME/$1/src:$HOME/$1/src" \
        --volume="/etc/group:/etc/group:rw" \
        --volume="/etc/passwd:/etc/passwd:rw" \
        --volume="/etc/shadow:/etc/shadow:rw" \
        --volume="/etc/sudoers:/etc/sudoers:rw" \
        --volume="/etc/sudoers.d:/etc/sudoers.d:rw" \
        --volume="$HOME/.ros:$HOME/.ros" \
        --volume="$HOME/.gazebo:$HOME/.gazebo" \
        --volume="$HOME/.ignition:$HOME/.ignition" \
        --volume="$HOME/.rviz:$HOME/.rviz" \
        -it $FULL_IMAGE_NAME $SHELL -c "eval export HOME=$HOME; cd $HOME; export XBOT_ROOT=$HOME/$1/install.sh; source /opt/ros/$2/setup.bash; bash"
}

function run_docker_ros_workspace()
{
        docker run --user root:root --hostname $HOSTNAME --ipc=host --net=$DOCKER_NET --device=/dev/dri:/dev/dri --privileged -e "QT_X11_NO_MITSHM=1" -e GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:/opt/ros/$1/share/wolf_gazebo_resources/models/ -e SHELL -e DISPLAY -e DOCKER=1 --name $CONTAINER_NAME \
        --gpus all \
        --device=/dev/ttyUSB0 \
        --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
        -it $FULL_IMAGE_NAME $SHELL -c "export XBOT_ROOT=/opt/ros/$1; source /opt/ros/$1/setup.bash; $CMD robot_model:=$ROBOT_MODEL world_name:=$WORLD_NAME full_gui:=$GUI input_device:=$DEVICE"
}

wolf_banner

if [[ ( $1 == "--help") ||  $1 == "-h" ]]
then
        echo -e $USAGE
        exit 0
fi

while [ -n "$1" ]; do # while loop starts

        case "$1" in

        -r|--robot)
                ROBOT_MODEL="$2"
                shift
                ;;

        -d|--device)
                DEVICE="$2"
                shift
                ;;

        -w|--world)
                WORLD_NAME="$2"
                shift
                ;;

        -g|--gui)
                GUI=true
                ;;

        -n|--net)
                DOCKER_NET=host
                ;;

        -l|--local)
                ROS_WS="$2"
                RUN_LOCAL_WS=true
                shift
                ;;

        -i|--image)
                IMAGE_NAME="$2"
                shift
                ;;

        -t|--tag)
                IMAGE_TAG="$2"
                shift
                ;;

        *) print_warn "Option $1 not recognized!"
                echo -e $USAGE
                exit 0;;

        esac

        shift
done

# Validating options
valid_robots=("spot" "go1")
valid_devices=("ps3" "xbox" "twist" "keyboard")
valid_worlds=("empty" "ruins" "pyramid" "ramps" "stairs" "office")
valid_tags=("focal" "jammy")

if [[ ! " ${valid_robots[*]} " =~ " $ROBOT_MODEL " ]]; then
    print_warn "Invalid robot model!"
    echo -e "$USAGE"
    exit 1
fi

if [[ ! " ${valid_devices[*]} " =~ " $DEVICE " ]]; then
    print_warn "Invalid input device!"
    echo -e "$USAGE"
    exit 1
fi

if [[ ! " ${valid_worlds[*]} " =~ " $WORLD_NAME " ]]; then
    print_warn "Invalid world name!"
    echo -e "$USAGE"
    exit 1
fi

if [[ ! " ${valid_tags[*]} " =~ " $IMAGE_TAG " ]]; then
    print_warn "Invalid image tag!"
    echo -e "$USAGE"
    exit 1
elif [[ $IMAGE_TAG == "focal" ]]; then
    ROS=noetic
    CMD='roslaunch wolf_controller wolf_controller_bringup.launch'
elif [[ $IMAGE_TAG == "jammy" ]]; then
    ROS=humble
    CMD='ros2 launch wolf_controller wolf_controller_bringup.launch.xml'
fi

# Define the full Docker image name
FULL_IMAGE_NAME="$IMAGE_NAME:$IMAGE_TAG"

# Ensure Docker is running
if ! sudo systemctl is-active --quiet docker; then
    echo "Docker inactive. Starting docker..."
    sudo systemctl restart docker
fi

# Pull Docker image if not present
if ! docker image inspect "$FULL_IMAGE_NAME" > /dev/null 2>&1; then
    print_warn "Image $FULL_IMAGE_NAME not found. Pulling from registry..."
    docker pull "$DOCKER_REGISTRY/$FULL_IMAGE_NAME"
    docker tag "$DOCKER_REGISTRY/$FULL_IMAGE_NAME" "$FULL_IMAGE_NAME"
fi

# Cleanup existing Docker container if necessary
docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1 || true

# xhost settings to allow Docker GUI access
xhost +local:docker

# Run the container with shared X11
# Opt1 run the code within the docker container by sourcing the local ROS workspace (useful for development)
# Opt2 run the code within the docker container by sourcing the ROS workspace INSIDE docker (useful as a demo)
if $RUN_LOCAL_WS;
then
        print_info "Selected ros workspace: $ROS_WS"
        run_local_ros_workspace $ROS_WS $ROS

else
        run_docker_ros_workspace $ROS
fi
