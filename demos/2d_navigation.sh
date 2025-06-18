#!/usr/bin/env bash

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

set -e

source $SCRIPTPATH/../support/fun.cfg

wolf_banner

# Options
ROS=noetic
CONTAINER_NAME="wolf-app-noetic"
IMAGE_TAG="focal"
ROBOT_MODEL=go1
ROBOT_NAME=
WORLD_NAME=office
MAPPING=true
GAZEBO_GUI=true
NET=bridge

# Define the image name
IMAGE_NAME=serger87/$CONTAINER_NAME:$IMAGE_TAG

# Add docker to xhost
xhost +local:docker

if [ `sudo systemctl is-active docker` = "inactive" ]; then
  echo "Docker inactive. Starting docker..."
  sudo systemctl start docker
fi

# Only pull if the image is not already present locally
if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
  echo "Image $IMAGE_NAME not found locally. Pulling..."
  docker pull "$IMAGE_NAME"
else
  echo "Image $IMAGE_NAME already exists locally. Skipping pull."
fi

# Cleanup the docker container before launching it
docker rm -f $CONTAINER_NAME > /dev/null 2>&1 || true 

docker run --user root:root --hostname $HOSTNAME --ipc=host --net=$NET --device=/dev/dri:/dev/dri --privileged -e "QT_X11_NO_MITSHM=1" -e GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:/opt/ros/$ROS/share/wolf_gazebo_resources/models/ -e SHELL -e DISPLAY -e DOCKER=1 --name $CONTAINER_NAME \
	--gpus all \
	--device=/dev/ttyUSB0 \
	--volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
	--volume="$HOME/.Xauthority:/root/.Xauthority:rw" \
	--volume="/tmp:/tmp" \
	--volume="/etc/group:/etc/group:ro" \
	--volume="$HOME/.ros:/root/.ros"    \
	--volume="$HOME/.ssh:$HOME/.ssh:ro" \
	--volume="/etc/passwd:/etc/passwd:ro" \
	--volume="/etc/shadow:/etc/shadow:ro" \
	--volume="/etc/sudoers.d:/etc/sudoers.d:ro" \
        -it $IMAGE_NAME $SHELL -c "source /opt/ros/$ROS/setup.bash; export XBOT_ROOT=/opt/ros/${ROS}; roslaunch wolf_navigation_utils wolf_navigation.launch mapping:=$MAPPING world_name:=$WORLD_NAME robot_name:=$ROBOT_NAME robot_model:=$ROBOT_MODEL gazebo_gui:=$GAZEBO_GUI initial_xyz:=[0.0,0.0,5.0]"
