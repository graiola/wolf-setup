#!/bin/bash

#TODO ros_ws -> variable

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

set -e

sudo apt-get update && sudo apt-get install -y python-bloom fakeroot

source /opt/ros/$ROS_DISTRO/setup.bash
source $HOME/ros_ws/devel/setup.bash
source /opt/xbot/setup.sh
export CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH:/opt/xbot/lib/cmake

OS=ubuntu
OS_VERSION=$(lsb_release -cs)

rosdep update

PKGS=$(cat $SCRIPTPATH/../config/wbc_list.txt | grep -v \#)

for PKG in $PKGS
do
	roscd $PKG

	bloom-generate rosdebian --os-name $OS --os-version $OS_VERSION --ros-distro $ROS_DISTRO

	echo -e "override_dh_usrlocal:" >> debian/rules
	echo -e "override_dh_shlibdeps:" >> debian/rules
	echo -e "	dh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info" >> debian/rules

        fakeroot debian/rules binary
        #dpkg-buildpackage -nc -d -uc -us

	sudo dpkg -i ../*.deb

	mv ../*.deb $SCRIPTPATH/$OS_VERSION
	
	rm -rf debian obj-x86_64-linux-gnu

done
