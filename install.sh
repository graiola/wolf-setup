#!/bin/bash

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

set -e

source $SCRIPTPATH/support/fun.cfg

USAGE="Usage: \n install [OPTIONS...]
\n\n
Help Options:
\n 
-h,--help \tShow help options
\n\n
Application Options:
\n 
-i,--install \tInstall options [base|app|all], example: -i all
\n 
-b,--branch \tBranch to install, example: -b devel"

# Default
INSTALL_OPT=all
BRANCH_OPT=devel

wolf_banner

if [[ ( $1 == "--help") ||  $1 == "-h" ]] 
then 
	echo -e $USAGE
	exit 0
fi

while [ -n "$1" ]; do # while loop starts
	case "$1" in
	-i|--install)
		INSTALL_OPT="$2"
		shift
		;;
	-b|--branch)
		BRANCH_OPT="$2"
		shift
		;;
	*) print_warn "Option $1 not recognized!" 
		echo -e $USAGE
		exit 0;;
	esac
	shift
done

# Checks
if [[ ( $INSTALL_OPT == "base") ||  ( $INSTALL_OPT == "app") ||  ( $INSTALL_OPT == "all")]] 
then 
	print_info "Selected install option: $INSTALL_OPT"
else
	print_warn "Wrong install option!"
	echo -e $USAGE
	exit 0
fi

# Check ubuntu version and select the right ROS
UBUNTU=$(lsb_release -cs)
if   [ $UBUNTU == "jammy" ]; then
	ROS_VERSION_NAME=ros2
	ROS_DISTRO=humble
	PYTHON_NAME=python3
elif [ $UBUNTU == "focal" ]; then
	ROS_VERSION_NAME=ros
	ROS_DISTRO=noetic
	PYTHON_NAME=python3
else
	print_warn "Wrong Ubuntu! This script supports Ubuntu 20.04 - 22.04"
	exit
fi

if [[ ( $INSTALL_OPT == "base") || ( $INSTALL_OPT == "all") ]]
then 
        sudo sh -c "echo 'deb http://packages.ros.org/${ROS_VERSION_NAME}/ubuntu $(lsb_release -cs) main' > /etc/apt/sources.list.d/ros-latest.list"
	wget https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -O - | sudo apt-key add -
	sudo apt-get update
	print_info "Install system libraries"
	cat $SCRIPTPATH/config/${ROS_VERSION_NAME}/sys_deps_list.txt | grep -v \# | xargs sudo apt-get install -y
	print_info "Install python libraries"
	cat $SCRIPTPATH/config/${ROS_VERSION_NAME}/python_deps_list.txt | grep -v \# | xargs printf -- "${PYTHON_NAME}-%s\n" | xargs sudo apt-get install -y
	print_info "Install ROS packages"
	cat $SCRIPTPATH/config/${ROS_VERSION_NAME}/ros_deps_list.txt | grep -v \# | xargs printf -- "ros-${ROS_DISTRO}-%s\n" | xargs sudo apt-get install -y
	sudo ldconfig
	sudo rosdep init || true
	rosdep update
fi

if [[ ( $INSTALL_OPT == "app") || ( $INSTALL_OPT == "all") ]]
then 
	# Download the debians
	/bin/bash $SCRIPTPATH/support/get_debians.sh
	print_info "Install WoLF debian packages"
	sudo dpkg -i --force-overwrite $SCRIPTPATH/debs/$BRANCH_OPT/$UBUNTU/*.deb
fi

# Setup Bashrc
if grep -Fwq "/opt/ros/${ROS_DISTRO}/setup.bash" ~/.bashrc
then 
	print_info "Bashrc is already updated with /opt/ros/${ROS_DISTRO}/setup.bash"
else
	print_info "Add /opt/ros/${ROS_DISTRO}/setup.bash to the bashrc"
	echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc
fi
if grep -Fwq "/opt/ocs2/setup.sh" ~/.bashrc
then 
 	print_info "Bashrc is already updated with /opt/ocs2/setup.sh"
else
	print_info "Add /opt/ocs2/setup.sh to the bashrc"
	echo "source /opt/ocs2/setup.sh" >> ~/.bashrc
fi
if grep -Fwq "export XBOT_ROOT=/opt/ros/${ROS_DISTRO}" ~/.bashrc
then 
	print_info "Bashrc is already updated with export XBOT_ROOT=/opt/ros/${ROS_DISTRO}"
else
	print_info "Add export XBOT_ROOT=/opt/ros/${ROS_DISTRO} to the bashrc"
	echo "export XBOT_ROOT=/opt/ros/${ROS_DISTRO}" >> ~/.bashrc
fi

