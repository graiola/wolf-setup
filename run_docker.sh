#!/usr/bin/env bash

source ./fun.cfg

USAGE="Usage: \n run_docker [OPTIONS...] \n\nHelp Options:\n -h,--help \tShow help options\n\nApplication Options:\n -r \tRobot name: -r [hyq|anymal]\n -w \tWorld name: -w [empty|ruins]\n -a \tAdd the arm to the robot, available only for hyq\n -g \tLaunch rviz\n -n \tLaunch docker with shared network, useful to visualize the ROS topics on the host machine\n -l \tSource the local ROS workspace: -l [workspace]"

# Default
ROBOT_NAME=hyq
WORLD_NAME=empty
ARM=false
GUI=false
RUN_LOCAL_WS=false
DOCKER_NET=bridge
ROS_WS=
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

	-g)    
	        GUI=true
		shift
		;;

	-n)    
	        DOCKER_NET=host
                shift
		;;

	-l)    
	        ROS_WS="$2"
		RUN_LOCAL_WS=true
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
