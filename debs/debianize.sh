#!/bin/bash

sudo apt-get update && apt-get install -y python-bloom fakeroot

source /opt/ros/$ROS_DISTRO/setup.bash
source $HOME/ros_ws/devel/setup.bash
source /opt/ros/advr-superbuild/setup.bash

WORKING_DIR=`pwd`

rosdep update	

PKGS="teleop_description sensors_description teleop_description anymal_description aliengo_description hyq_description dls_gazebo_interface dls_gazebo_resources dls_hardware_interface rt_logger wb_controller"

for PKG in $PKGS
do
	roscd $PKG

	bloom-generate rosdebian --os-name ubuntu --os-version bionic --ros-distro $ROS_DISTRO

	echo -e "override_dh_usrlocal:" >> debian/rules
	echo -e "override_dh_shlibdeps:" >> debian/rules
	echo -e "	dh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info" >> debian/rules

	fakeroot debian/rules binary
	#dpkg-buildpackage -nc -d

	sudo dpkg -i ../*.deb

	mv ../*.deb $WORKING_DIR
	
	rm -rf debian obj-x86_64-linux-gnu

done
