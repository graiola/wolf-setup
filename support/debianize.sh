#!/bin/bash

#This script uses the system ROS_DISTRO and ubuntu version
#Branch is treated as a folder, so be sure that the git repository is in the correct branch!
#git name-rev --name-only HEAD

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

source $SCRIPTPATH/fun.cfg

USAGE="Usage: \n debianize [OPTIONS...]
\n\n
Help Options:
\n 
-h,--help \tShow help options
\n\n
Application Options:
\n 
-b,--branch \tBranch to install, example: -b devel
\n
-w, --workspace \tWorkspace to debianize, example: -w ros_ws
"

# Default
BRANCH=devel
OS=ubuntu
ROS_WS=ros_ws

if [[ ( $1 == "--help") ||  $1 == "-h" ]] 
then 
	echo -e $USAGE
	exit 0
fi

while [ -n "$1" ]; do # while loop starts
	case "$1" in
	-b|--branch)
		BRANCH="$2"
		shift
		;;
	-w|--workspace)
		ROS_WS="$2"
		shift
		;;
	*) echo "Option $1 not recognized!" 
		echo -e $USAGE
		exit 0;;
	esac
	shift
done

# Clean
clean_file     $SCRIPTPATH/../debs/wolf.zip
clean_folder   $SCRIPTPATH/../debs/$BRANCH

# Check ubuntu version and select the right ROS
OS_VERSION=$(lsb_release -cs)
if   [ $OS_VERSION == "bionic" ]; then
	PYTHON_NAME=python
elif [ $OS_VERSION == "focal" ]; then
	PYTHON_NAME=python3
else
	echo -e "${COLOR_WARN}Wrong Ubuntu! This script supports Ubuntu 18.04 - 20.04${COLOR_RESET}"
fi

sudo apt-get update && sudo apt-get install -y ${PYTHON_NAME}-bloom fakeroot

source /opt/ros/$ROS_DISTRO/setup.bash
source $HOME/$ROS_WS/devel/setup.bash
source /opt/xbot/setup.sh
export CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH:/opt/xbot/lib/cmake

rosdep update

PKGS=$(cat $SCRIPTPATH/../config/wolf_list.txt | grep -v \#)

for PKG in $PKGS
do
	roscd $PKG

	bloom-generate rosdebian --os-name $OS --os-version $OS_VERSION --ros-distro $ROS_DISTRO

	echo -e "override_dh_usrlocal:" >> debian/rules
	echo -e "override_dh_shlibdeps:" >> debian/rules
	echo -e "	dh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info" >> debian/rules

	fakeroot debian/rules binary
	#dpkg-buildpackage -nc -d -uc -us
	#sudo dpkg -i ../*.deb

	mkdir -p $SCRIPTPATH/../debs/$BRANCH/$OS_VERSION && mv ../*.deb $SCRIPTPATH/../debs/$BRANCH/$OS_VERSION
	
	rm -rf debian obj-x86_64-linux-gnu

done
