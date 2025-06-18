#!/bin/bash
set -e

source /opt/ros/${ROS_DISTRO}/setup.bash
mkdir -p /tmp/debs/${BRANCH}/${UBUNTU}

# Clone or assume mounted workspace
if [[ -z "$ROS_LOCAL" || "$ROS_LOCAL" == "false" ]]; then
  rm -rf ros_ws/src
  mkdir -p ros_ws/src
  git clone -b ${BRANCH} --recursive git@github.com:graiola/wolf.git ros_ws/src/wolf
fi

cd ros_ws

if [[ "$ROS_VERSION" == "1" ]]; then
  catkin_init_workspace src
  catkin config --install
  catkin build -DCMAKE_BUILD_TYPE=Release
  ./src/wolf/setup/support/debianize_ros.sh -b ${BRANCH}
else
  colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS='-w'
  ./src/wolf/setup/support/debianize_ros2.sh -b ${BRANCH}
fi

echo "yaml https://raw.githubusercontent.com/graiola/wolf-setup/master/config/${ROS_DISTRO}/wolf.yaml" \
  | sudo tee /etc/ros/rosdep/sources.list.d/20-default.list

mv ./src/wolf/setup/debs/${BRANCH}/${UBUNTU}/*.deb /tmp/debs/${BRANCH}/${UBUNTU}/
echo "Debians generated and moved to /tmp folder"

