#!/usr/bin/env bash

# These are fixed
CONTAINER_NAME="wbc"
IMAGE_NAME="wbc:latest"
USAGE="Usage: ./run.sh [ROBOT_NAME=hyq|anymal] [WORLD_NAME=empty|ruins]\nExample: ./run.sh hyq ruins"

# Check args
if [[ ( $1 == "--help") ||  $1 == "-h" ]] 
then 
	echo -e $USAGE
	exit 0
fi
if [ "$#" -lt 2 ]; then
	WORLD_NAME=empty
else
	WORLD_NAME=$2
fi
if [ "$#" -lt 1 ]; then
	ROBOT_NAME=hyq
else
	ROBOT_NAME=$1
fi 

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

set -e

# Hacky
xhost +local:docker


if [ `sudo systemctl is-active docker` = "inactive" ]; then
  echo "Docker inactive.  Starting docker..."
  sudo systemctl start docker
fi

# Cleanup the docker container before launching it
docker rm -f $CONTAINER_NAME > /dev/null 2>&1 || true 

# Run the container with shared X11
docker run --user `id -u`:sudo --hostname $HOSTNAME --device=/dev/dri:/dev/dri --privileged -e "QT_X11_NO_MITSHM=1" -e GAZEBO_MODEL_PATH=/opt/ros/melodic/share/dls_gazebo_resources/models/ -e SHELL -e DISPLAY -e DOCKER=1 --name $CONTAINER_NAME \
--gpus all \
--device=/dev/ttyUSB0 \
--volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
--workdir="/home/$USER" \
--volume="/etc/group:/etc/group:ro" \
--volume="/etc/passwd:/etc/passwd:ro" \
--volume="/etc/shadow:/etc/shadow:ro" \
--volume="/etc/sudoers.d:/etc/sudoers.d:ro" \
--volume="$HOME/.ros:$HOME/.ros" \
--volume="$HOME/.gazebo:$HOME/.gazebo" \
--volume="$HOME/.ignition:$HOME/.ignition" \
-it $IMAGE_NAME $SHELL -c "eval export HOME=$HOME; cd $HOME; source /opt/ros/melodic/setup.bash; source /opt/ros/advr-superbuild/setup.bash; roslaunch wb_controller wb_controller_bringup.launch robot_name:=$ROBOT_NAME world_name:=$WORLD_NAME.world"
