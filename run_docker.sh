#!/usr/bin/env bash

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

set -e

source $SCRIPTPATH/fun.cfg

USAGE="Usage: \n run_docker [OPTIONS...] 
\n\n
Help Options:
\n 
-h,--help \tShow help options
\n\n
Application Options:
\n 
-r,--robot \tRobot name [hyq|anymal|aliengo|spot], example: -r anymal
\n 
-w,--world \tWorld name [empty|ruins], example: -w ruins
\n 
-g,--gui \tLaunch rviz
\n 
-n,--net \tLaunch docker with shared network, useful to visualize the ROS topics on the host machine
\n 
-l,--local \tRun a local ROS workspace inside the container [workspace], example: -l ros_ws
\n 
-i,--image \tSelect the docker image to run [image], example: -i bionic"

# Default
ROBOT_NAME=spot
WORLD_NAME=empty
GUI=false
RUN_LOCAL_WS=false
DOCKER_NET=bridge
ROS_WS=
CONTAINER_NAME="wbc"
IMAGE_TAG="bionic"

if [[ ( $1 == "--help") ||  $1 == "-h" ]] 
then 
	echo -e $USAGE
	exit 0
fi

while [ -n "$1" ]; do # while loop starts

	case "$1" in

         -r|--robot)
    		ROBOT_NAME="$2"
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
	        IMAGE_TAG="$2"
                shift
		;;

	*) echo "Option $1 not recognized!" 
		echo -e $USAGE
		exit 0;;

	esac

	shift
done

# Checks
if [[ ( $ROBOT_NAME == "hyq") ||  ( $ROBOT_NAME == "anymal") ||  ( $ROBOT_NAME == "aliengo") ||  ( $ROBOT_NAME == "spot") ]] 
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

if [[ ( $IMAGE_TAG == "bionic") ]] 
then 
	ROS_DISTRO=melodic
	echo "Selected docker image: $IMAGE_TAG"
else
	echo "Wrong image option!"
	echo -e $USAGE
	exit 0
fi

# Define the image name
IMAGE_NAME=$CONTAINER_NAME:$IMAGE_TAG

# Hacky
xhost +local:docker

if [ `sudo systemctl is-active docker` = "inactive" ]; then
  echo "Docker inactive. Starting docker..."
  sudo systemctl start docker
fi

# Cleanup the docker container before launching it
docker rm -f $CONTAINER_NAME > /dev/null 2>&1 || true 

# Run the container with shared X11
# Opt1 run the code within the docker container by sourcing the local ROS workspace (useful for development)
# Opt2 run the code within the docker container by sourcing the ROS workspace INSIDE docker (useful as a demo)
if $RUN_LOCAL_WS;
then 
	if [ -f "$HOME/$ROS_WS/devel/setup.bash" ];
	then
		echo "Selected ros workspace: $ROS_WS"
		run_local_ros_workspace $ROS_WS
	else
		echo "The file $HOME/$ROS_WS/devel/setup.bash does not exist!"
		echo -e $USAGE
		exit 0
	fi
else
	run_docker_ros_workspace
fi
