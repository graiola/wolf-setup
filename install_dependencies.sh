#!/bin/bash

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

set -e

source $SCRIPTPATH/fun.cfg

# Check ubuntu version and select the right ROS
UBUNTU=$(lsb_release -cs)
if   [ $UBUNTU == "bionic" ]; then
	ROS_DISTRO=melodic
elif [ $UBUNTU == "xenial" ]; then
	ROS_DISTRO=kinetic
elif [ $UBUNTU == "focal" ]; then
        ROS_DISTRO=noetic
else
    echo -e "${COLOR_WARN}Wrong Ubuntu! This code runs on Ubuntu 16.04 - 18.04 - 20.04${COLOR_RESET}"
fi

sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros-latest.list'
wget https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -O - | sudo apt-key add -
sudo apt-get update

echo -e "${COLOR_INFO}Install system libraries${COLOR_RESET}"
cat $SCRIPTPATH/config/sys_deps_list.txt | grep -v \# | xargs sudo apt-get install -y

echo -e "${COLOR_INFO}Install ROS packages${COLOR_RESET}"
cat $SCRIPTPATH/config/ros_deps_list.txt | grep -v \# | xargs printf -- "ros-${ROS_DISTRO}-%s\n" | xargs sudo apt-get install -y

sudo ldconfig

sudo rosdep init
rosdep update

echo -e "${COLOR_INFO}Install the WBC debian packages${COLOR_RESET}"
sudo dpkg -i --force-overwrite $SCRIPTPATH/debs/$UBUNTU/*.deb

echo -e "${COLOR_INFO}Install the ADVR debian packages${COLOR_RESET}"
sudo $SCRIPTPATH/debs/$UBUNTU/advr/install.sh

# Setup Bashrc
if grep -Fwq "/opt/ros/${ROS_DISTRO}/setup.bash" ~/.bashrc
then 
 	echo -e "${COLOR_INFO}Bashrc already updated, skipping this step...${COLOR_RESET}"
else
    	echo -e "${COLOR_INFO}Update the bashrc.${COLOR_RESET}"
	echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc
fi

if grep -Fwq "/opt/xbot/setup.bash" ~/.bashrc
then 
 	echo -e "${COLOR_INFO}Bashrc already updated, skipping this step...${COLOR_RESET}"
else
    	echo -e "${COLOR_INFO}Update the bashrc.${COLOR_RESET}"
	echo "source /opt/xbot/setup.bash" >> ~/.bashrc
fi
