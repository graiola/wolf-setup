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
BUILD_OCS2=${BUILD_OCS2:-false}
INSTALL_OCS2_FROM_DEBS=false
export DEBS_OUT="/tmp/debs/${BRANCH}/${UBUNTU}"
mkdir -p "$DEBS_OUT"

source /opt/ros/${ROS_DISTRO}/setup.bash

# ---------------------------
# Build OCS2 from source (optional, ROS 1 only)
# ---------------------------
if [[ "$ROS_VERSION" == "1" && "$BUILD_OCS2" == "true" ]]; then
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
elif [[ "$BUILD_OCS2" == "true" ]]; then
  echo "[WARN] BUILD_OCS2=true ignored for ROS_VERSION=${ROS_VERSION}. OCS2 build is supported only on ROS 1."
else
  echo "[INFO] Skipping OCS2 build (BUILD_OCS2=${BUILD_OCS2})"
fi

# If OCS2 build is disabled on ROS1, require a preinstalled OCS2 and source it.
if [[ "$ROS_VERSION" == "1" && "$BUILD_OCS2" != "true" ]]; then
  if [[ -f /opt/ocs2/setup.sh ]]; then
    echo "[INFO] Using preinstalled OCS2 from /opt/ocs2"
    source /opt/ocs2/setup.sh
  else
    echo "[INFO] /opt/ocs2 not found. Will install OCS2 debian with get_debians.sh."
    INSTALL_OCS2_FROM_DEBS=true
  fi
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

if [[ "$INSTALL_OCS2_FROM_DEBS" == "true" ]]; then
  echo "[INFO] Downloading WoLF debians..."
  /bin/bash ./src/wolf/setup/support/get_debians.sh

  OCS2_DEB_DIR="./src/wolf/setup/debs/${BRANCH}/${UBUNTU}"
  mapfile -t OCS2_DEBS < <(find "$OCS2_DEB_DIR" -maxdepth 1 -type f -name "*ocs2*.deb" | sort)

  if [[ ${#OCS2_DEBS[@]} -eq 0 ]]; then
    echo "[ERROR] No OCS2 debian found in ${OCS2_DEB_DIR}"
    exit 1
  fi

  echo "[INFO] Installing OCS2 debian(s): ${OCS2_DEBS[*]}"
  sudo dpkg -i --force-overwrite "${OCS2_DEBS[@]}" || true
  sudo apt-get install -f -y

  if [[ ! -f /opt/ocs2/setup.sh ]]; then
    echo "[ERROR] OCS2 install failed: /opt/ocs2/setup.sh still missing"
    exit 1
  fi

  source /opt/ocs2/setup.sh
  echo "[INFO] OCS2 installed from downloaded debians"
fi

# RBDL is expected from image dependencies/rosdep. No manual install step here.

# ---------------------------
# Build and debianize
# ---------------------------
if [[ "$ROS_VERSION" == "1" ]]; then
  echo "[INFO] Building ROS 1 workspace..."
  catkin_init_workspace src
  catkin config --install

  # Bootstrap message/gui packages first. Support both legacy and current message package names.
  PREBUILD_PKGS="rt_gui_ros"
  if [[ -d "./src/wolf/ai_utils_msgs" ]]; then
    PREBUILD_PKGS="ai_utils_msgs ${PREBUILD_PKGS}"
  elif [[ -d "./src/wolf/wolf_msgs" ]]; then
    PREBUILD_PKGS="wolf_msgs ${PREBUILD_PKGS}"
  fi

  catkin build ${PREBUILD_PKGS} -DCMAKE_BUILD_TYPE=Release
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
