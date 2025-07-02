#!/bin/bash
set -e

# ---------------------------
# Validate and initialize
# ---------------------------
if [[ -z "$ROS_DISTRO" ]]; then
  echo "[ERROR] ROS_DISTRO is not set!"
  exit 1
fi

if [[ -z "$ROS_VERSION" ]]; then
  echo "[ERROR] ROS_VERSION is not set (expected '1' or '2')!"
  exit 1
fi

ROS_WS=${ROS_WS:-ros_ws}
export DEBS_OUT="/tmp/debs/${BRANCH}/${UBUNTU}"
mkdir -p "$DEBS_OUT"

source /opt/ros/${ROS_DISTRO}/setup.bash

# ---------------------------
# Build OCS2 from source (ROS 1 only)
# ---------------------------
if [[ "$ROS_VERSION" == "1" ]]; then
  echo "[INFO] Building OCS2 stack..."
  OCS2_WS=ocs2_ws
  rm -rf $OCS2_WS/src
  mkdir -p $OCS2_WS/src

  git clone -b main --recursive git@github.com:graiola/ocs2.git $OCS2_WS/src/ocs2
  git clone -b main --recursive git@github.com:graiola/ocs2_robotic_assets.git $OCS2_WS/src/ocs2_robotic_assets

  cd $OCS2_WS
  catkin_init_workspace src
  catkin_make -DCATKIN_WHITELIST_PACKAGES='ocs2_thirdparty;ocs2_core;ocs2_legged_robot_ros;ocs2_self_collision_visualization;ocs2_robotic_tools;ocs2_oc;ocs2_pinocchio_interface;ocs2_self_collision;ocs2_ros_interfaces;ocs2_msgs;ocs2_mpc;ocs2_ddp;ocs2_qp_solver;ocs2_sqp;blasfeo_catkin;hpipm_catkin;ocs2_ipm;ocs2_centroidal_model;ocs2_robotic_assets;ocs2_legged_robot' \
              -DCMAKE_BUILD_TYPE=Release \
              -DCMAKE_INSTALL_PREFIX=/opt/ocs2

  cd build
  sudo checkinstall --pkgname=wolf_ocs2 --pkgversion=1.0.0 --pkgarch=amd64 -y
  sudo dpkg -i --force-overwrite wolf-ocs2*.deb
  mv wolf-ocs2*.deb "$DEBS_OUT"
  source /opt/ocs2/setup.sh
  cd ~

  echo "[INFO] OCS2 installed and .deb moved"
fi

# ---------------------------
# Clone workspace if not local
# ---------------------------
if [[ -z "$ROS_LOCAL" || "$ROS_LOCAL" == "false" ]]; then
  echo "[INFO] Cloning wolf workspace from GitHub"
  rm -rf ${ROS_WS}/src
  mkdir -p ${ROS_WS}/src
  git clone -b ${BRANCH} --recursive git@github.com:graiola/wolf.git ${ROS_WS}/src/wolf
fi

cd $ROS_WS

# ---------------------------
# Install RBDL
# ---------------------------
# FIXME I should remove this line one day....
#if [[ "$ROS_VERSION" == "1" ]]; then
#  echo "[INFO] Install RBDL..."
#  /bin/bash ./src/wolf/setup/support/get_debians.sh &&
#  sudo dpkg -i --force-overwrite ./src/wolf/setup/debs/${BRANCH}/${UBUNTU}/rbdl-x86_64-linux-gnu-2.5.0.deb || true
#  echo "[INFO] RBDL installed"
#fi

# ---------------------------
# Build and debianize
# ---------------------------
if [[ "$ROS_VERSION" == "1" ]]; then
  echo "[INFO] Building ROS 1 workspace..."
  catkin_init_workspace src
  catkin config --install
  catkin build ai_utils_msgs rt_gui_ros -DCMAKE_BUILD_TYPE=Release
  source ./install/setup.bash
  catkin build -DCMAKE_BUILD_TYPE=Release
  ./src/wolf/setup/support/debianize_ros.sh -b "${BRANCH}" -w "${ROS_WS}"
else
  echo "[INFO] Building ROS 2 workspace..."
  colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS='-w'
  ./src/wolf/setup/support/debianize_ros2.sh -b "${BRANCH}"
fi

# ---------------------------
# Add rosdep config
# ---------------------------
echo "yaml https://raw.githubusercontent.com/graiola/wolf-setup/master/config/${ROS_DISTRO}/wolf.yaml" \
  | sudo tee /etc/ros/rosdep/sources.list.d/20-default.list

# ---------------------------
# Finalize
# ---------------------------
if compgen -G "./src/wolf/setup/debs/${BRANCH}/${UBUNTU}/*.deb" > /dev/null; then
  mv ./src/wolf/setup/debs/${BRANCH}/${UBUNTU}/*.deb "$DEBS_OUT/"
  echo "[INFO] Debians moved to $DEBS_OUT"
else
  echo "[WARN] No .deb files found to move"
fi

echo "[✔] Done!"

