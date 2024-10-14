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
-b,--branch\tBranch to install, example: -b devel
\n
-w, --workspace\tWorkspace to debianize, example: -w ros_ws
\n
-p, --pkg\tSelect package to compile, example: -p package_name
"

# Default
BRANCH=devel
OS=ubuntu
ROS_WS=ros_ws
ROS_VERSION_NAME=ros
ROS_DISTRO=noetic
SINGLE_PKG=

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
	-p|--pkg)
		SINGLE_PKG="$2"
		shift
		;;
	*) echo print_warn "Option $1 not recognized!" 
		echo -e $USAGE
		exit 0;;
	esac
	shift
done

# Clean
clean_file $SCRIPTPATH/../debs/wolf.zip
clean_folder $SCRIPTPATH/../debs/$BRANCH

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

sudo apt-get update && sudo apt-get install -y ${PYTHON_NAME}-bloom fakeroot

unset ROS_PACKAGE_PATH
source /opt/ros/$ROS_DISTRO/setup.bash
source /opt/ocs2/setup.sh
source $HOME/$ROS_WS/devel/setup.bash
export CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH:/opt/ocs2/share

echo -e "${COLOR_WARN}+++++++++++++ ROS:${COLOR_RESET}"
echo -e $ROS_VERSION_NAME
echo -e $ROS_DISTRO
echo -e $ROS_WS
echo -e "${COLOR_WARN}+++++++++++++:${COLOR_RESET}"

echo -e "${COLOR_WARN}+++++++++++++ ROS PACKAGE PATH:${COLOR_RESET}"
echo -e $ROS_PACKAGE_PATH
echo -e "${COLOR_WARN}+++++++++++++:${COLOR_RESET}"

rosdep update

function build()
{

    bloom-generate rosdebian --os-name $OS --os-version $OS_VERSION --ros-distro $ROS_DISTRO

    echo -e "override_dh_usrlocal:" >> debian/rules
    echo -e "override_dh_shlibdeps:" >> debian/rules
    echo -e "	dh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info" >> debian/rules

    fakeroot debian/rules binary
    #dpkg-buildpackage -nc -d -uc -us
    sudo dpkg -i ../*.deb

    mkdir -p $SCRIPTPATH/../debs/$BRANCH/$OS_VERSION && mv ../*.deb $SCRIPTPATH/../debs/$BRANCH/$OS_VERSION

    rm -rf debian obj-x86_64-linux-gnu
}


if [[ ( $SINGLE_PKG != "") ]]
then

    roscd $SINGLE_PKG
    build

else

    PKGS=$(cat $SCRIPTPATH/../config/$ROS_VERSION_NAME/wolf_list.txt | grep -v \#)

    for PKG in $PKGS
    do
            roscd $PKG

            if [[ $? == 0 ]]
            then
               build
            else
                print_warn "${PKG} is not available"
            fi

    done

 fi
