#!/bin/bash

# This script builds Debian packages for ROS 2 workspaces.

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

USAGE="Usage: \n build_debian [OPTIONS...]
\n\n
Help Options:
\n
-h,--help \tShow help options
\n\n
Application Options:
\n
-b,--branch\tBranch to install, example: -b devel
\n
-w, --workspace\tWorkspace to build, example: -w ros_ws
\n
-p, --pkg\tSelect package to compile, example: -p package_name
"

# Default Values
BRANCH=devel
ROS_WS=ros_ws
OS=ubuntu
OS_VERSION=$(lsb_release -cs)
ROS_DISTRO=humble
SINGLE_PKG=

if [[ ( $1 == "--help") ||  $1 == "-h" ]]; then
  echo -e $USAGE
  exit 0
fi

# Parse Arguments
while [ -n "$1" ]; do
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
    *)
      echo "Option $1 not recognized!"
      echo -e $USAGE
      exit 1
      ;;
  esac
  shift
done

# Check OS and set dependencies
if [[ $OS_VERSION == "jammy" ]]; then
  ROS_DISTRO=humble
elif [[ $OS_VERSION == "focal" ]]; then
  ROS_DISTRO=foxy
else
  echo "Unsupported Ubuntu version! This script supports Ubuntu 20.04 (Focal) and 22.04 (Jammy)."
  exit 1
fi

# Install necessary tools
sudo apt-get update && sudo apt-get install -y debhelper build-essential dh-make python3-bloom fakeroot ros-$ROS_DISTRO-ros-base

# Source ROS 2 environment
source /opt/ros/$ROS_DISTRO/setup.bash
source ~/$ROS_WS/install/setup.bash || {
  echo "Workspace not built or install/setup.bash not found."
  exit 1
}

rosdep update

# Clean previous build artifacts
rm -rf $SCRIPTPATH/../debs/$BRANCH
mkdir -p $SCRIPTPATH/../debs/$BRANCH

# Build Debian Packages
function build_package() {
  local PKG=$1
  PACKAGE_PATH=$(find $HOME/$ROS_WS/src -type d -name "$PKG" ! -path '*.git*' | head -n 1)
  cd $PACKAGE_PATH || {
    echo "Package $PKG not found in the workspace."
    return 1
  }

  echo "Generating Debian package for $PKG..."

  # Run bloom to generate Debian files
  bloom-generate rosdebian --os-name $OS --os-version $OS_VERSION --ros-distro $ROS_DISTRO || {
    echo "Bloom generation failed for $PKG."
    return 1
  }

  # Ensure debian/rules file uses tabs, not spaces
  sed -i 's/^    /\t/' debian/rules

  # Build the package
  fakeroot debian/rules binary || {
    echo "Debian package build failed for $PKG."
    return 1
  }

  # Move the generated .deb file
  mkdir -p $SCRIPTPATH/../debs/$BRANCH/$OS_VERSION
  mv ../*.deb $SCRIPTPATH/../debs/$BRANCH/$OS_VERSION || {
    echo "Failed to move .deb file for $PKG."
    return 1
  }

  # Clean up
  rm -rf debian obj-x86_64-linux-gnu
  echo "Debian package for $PKG created successfully."
}

# Build either a single package or all packages
if [[ -n $SINGLE_PKG ]]; then
  build_package $SINGLE_PKG
else
  PKGS=$(cat $SCRIPTPATH/../config/ros2/wolf_list.txt | grep -v \#)
  for PKG in $PKGS; do
    build_package $PKG || {
      echo "Skipping $PKG due to errors."
    }
  done
fi

echo "Debian packages generated successfully in $SCRIPTPATH/../debs/$BRANCH/$OS_VERSION."
