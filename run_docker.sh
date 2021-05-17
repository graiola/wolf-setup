#!/usr/bin/env bash

USAGE="Usage: \n run_docker [OPTIONS...] \n\nHelp Options:\n -h,--help \tShow help options\n\nApplication Options:\n -r \tRobot name (hyq,anymal)\n -w \tWorld name (empty,ruins)\n -a \tAdd the arm to the robot, available for hyq only"

# Default
ROBOT_NAME=hyq
WORLD_NAME=empty
ARM=false
GUI=false
CONTAINER_NAME="wbc"
IMAGE_NAME="wbc:latest"

if [[ ( $1 == "--help") ||  $1 == "-h" ]] 
then 
	echo -e $USAGE
	exit 0
fi

while [ -n "$1" ]; do # while loop starts

	case "$1" in

        -r)
		ROBOT_NAME="$2"
		shift
		;;

	 -w)
		WORLD_NAME="$2"
		shift
		;;

	-a)    
	        ARM=true
		shift
		;;

	*) echo "Option $1 not recognized!" 
		echo -e $USAGE
		exit 0;;

	esac

	shift

done

# Checks
if [[ ( $ROBOT_NAME == "hyq") ||  ( $ROBOT_NAME == "anymal") ]] 
then 
	echo "Selected robot: $ROBOT_NAME"
else
	echo "Wrong robot option!"
	echo -e $USAGE
	exit 0
fi

if [[ ( $WORLD_NAME == "empty") ||  ( $WORLD_NAME == "ruins") ]] 
then 
	echo "Selected world: $WORLD_NAME"
else
	echo "Wrong world option!"
	echo -e $USAGE
	exit 0
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
-it $IMAGE_NAME $SHELL -c "eval export HOME=$HOME; cd $HOME; source /opt/ros/melodic/setup.bash; source /opt/ros/advr-superbuild/setup.bash; roslaunch wb_controller wb_controller_bringup.launch robot_name:=$ROBOT_NAME world_name:=$WORLD_NAME.world arm:=$ARM full_gui:=$GUI"
