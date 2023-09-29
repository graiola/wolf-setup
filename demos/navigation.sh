#!/usr/bin/env bash

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

set -e

source $SCRIPTPATH/../support/fun.cfg

echo ' 
###########################################
#                                         #
#                  WoLF                   #
#                                         #
#  https://github.com/graiola/wolf-setup  #
#                       .                 #
#                      / V\               #
#                    / .  /               #
#                   <<   |                #
#                   /    |                #
#                 /      |                #
#               /        |                #
#             /    \  \ /                 #
#            (      ) | |                 #
#    ________|   _/_  | |                 #
#  <__________\______)\__)                #
#                                         #
###########################################
'

# Options
ROS=noetic
CONTAINER_NAME="wolf-app"
IMAGE_TAG="focal"
ROBOT_MODEL=spot
ROBOT_NAME=
WORLD_NAME=office
MAPPING=true
GAZEBO_GUI=true
NET=bridge

if [[ ( $ROBOT_MODEL == "go1") ]]
then
	LIDAR_TOPIC=/rslidar_points
else
	LIDAR_TOPIC=/velodyne_points
fi

# Define the image name
IMAGE_NAME=serger87/$CONTAINER_NAME:$IMAGE_TAG

# Hacky
xhost +local:docker

if [ `sudo systemctl is-active docker` = "inactive" ]; then
  echo "Docker inactive. Starting docker..."
  sudo systemctl start docker
fi

# Cleanup the docker container before launching it
docker rm -f $CONTAINER_NAME > /dev/null 2>&1 || true 

docker run --user root:root --hostname $HOSTNAME --net=$NET --device=/dev/dri:/dev/dri --privileged -e "QT_X11_NO_MITSHM=1" -e GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:/opt/ros/$ROS/share/wolf_gazebo_resources/models/ -e SHELL -e DISPLAY -e DOCKER=1 --name $CONTAINER_NAME \
	--gpus all \
	--device=/dev/ttyUSB0 \
	--volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
        -it $IMAGE_NAME $SHELL -c "source /opt/ros/$ROS/setup.bash; source /opt/xbot/setup.sh; roslaunch wolf_navigation_utils wolf_navigation.launch mapping:=$MAPPING world_name:=$WORLD_NAME robot_name:=$ROBOT_NAME robot_model:=$ROBOT_MODEL gazebo_gui:=$GAZEBO_GUI lidar_topic:=$LIDAR_TOPIC initial_xyz:=[0.0,0.0,5.0]"
