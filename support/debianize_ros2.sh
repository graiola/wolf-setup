#!/bin/bash

# This script builds Debian packages for ROS 2 workspaces.

# Get this script's path
pushd "$(dirname "$0")" > /dev/null
SCRIPTPATH=$(pwd)
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
\n
-a, --all\tBuild the entire workspace into a single .deb package
"

# Default Values
BRANCH=devel
ROS_WS=ros_ws
OS=ubuntu
OS_VERSION=$(lsb_release -cs)
ROS_DISTRO=humble
SINGLE_PKG=
BUILD_ALL=true

if [[ ( $1 == "--help") ||  $1 == "-h" ]]; then
  echo -e "$USAGE"
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
    -a|--all)
      BUILD_ALL=true
      ;;
    *)
      echo "Option $1 not recognized!"
      echo -e "$USAGE"
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
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update && sudo apt-get install -y debhelper build-essential dh-make python3-bloom fakeroot ros-$ROS_DISTRO-ros-base

# Source ROS 2 environment
source /opt/ros/$ROS_DISTRO/setup.bash
source ~/$ROS_WS/install/setup.bash || {
  echo "Workspace not built or install/setup.bash not found."
  exit 1
}

rosdep update

# Clean previous build artifacts
rm -rf "$SCRIPTPATH/../debs/$BRANCH"
mkdir -p "$SCRIPTPATH/../debs/$BRANCH"

# === Build Functions ===

function build_package() {
  local PKG=$1
  PACKAGE_PATH=$(find "$HOME/$ROS_WS/src" -type d -name "$PKG" ! -path '*.git*' | head -n 1)
  cd "$PACKAGE_PATH" || {
    echo "Package $PKG not found in the workspace."
    return 1
  }

  echo "Generating Debian package for $PKG..."

  bloom-generate rosdebian --os-name $OS --os-version $OS_VERSION --ros-distro $ROS_DISTRO || {
    echo "Bloom generation failed for $PKG."
    return 1
  }

  echo -e "override_dh_usrlocal:\n" >> debian/rules
  echo -e "override_dh_shlibdeps:\n\tdh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info" >> debian/rules

  # Ensure debian/rules file uses tabs
  sed -i 's/^    /\t/' debian/rules

  fakeroot debian/rules binary || {
    echo "Debian package build failed for $PKG."
    return 1
  }

  mkdir -p "$SCRIPTPATH/../debs/$BRANCH/$OS_VERSION"
  mv ../*.deb "$SCRIPTPATH/../debs/$BRANCH/$OS_VERSION" || {
    echo "Failed to move .deb file for $PKG."
    return 1
  }

  rm -rf debian obj-x86_64-linux-gnu
  echo "Debian package for $PKG created successfully."
}

function build_all_workspace() {
  local WS_PATH="$HOME/$ROS_WS"
  local INSTALL_DIR="$WS_PATH/install"
  local DEB_DIR="$WS_PATH/debbuild/whole_ws"
  local VERSION="1.0.0"
  local OUTPUT_DEB="${SCRIPTPATH}/../debs/$BRANCH/$OS_VERSION/ros-${ROS_DISTRO}-wolf-full_${VERSION}_${OS_VERSION}_amd64.deb"

  echo "Building the entire workspace into one Debian package..."

  colcon build --merge-install --install-base "$INSTALL_DIR" || {
    echo "Workspace build failed"
    return 1
  }

  rm -rf "$DEB_DIR"
  mkdir -p "$DEB_DIR/DEBIAN"
  mkdir -p "$DEB_DIR/opt/ros/$ROS_DISTRO"
  cp -a "$INSTALL_DIR/"* "$DEB_DIR/opt/ros/$ROS_DISTRO"

  rm -f "$DEB_DIR/opt/ros/$ROS_DISTRO/_setup_util.py"
  rm -f "$DEB_DIR/opt/ros/$ROS_DISTRO/setup.*"
  rm -rf "$DEB_DIR/opt/ros/$ROS_DISTRO/share/colcon*"

  mkdir -p "$(dirname "$OUTPUT_DEB")"

  DEPS=$(rosdep check --from-paths "$WS_PATH/src" --rosdistro "$ROS_DISTRO" --ignore-src --reinstall 2>/dev/null | grep "apt:" | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')

  cat <<EOF > "$DEB_DIR/DEBIAN/control"
Package: ros-${ROS_DISTRO}-wolf-full
Version: $VERSION
Section: misc
Priority: optional
Architecture: amd64
Maintainer: ROS Maintainers <ros@ros.org>
Depends: $DEPS
Description: Monolithic .deb containing the entire ROS 2 workspace
EOF

  dpkg-deb --build "$DEB_DIR" "$OUTPUT_DEB"
  echo "✔ Built $OUTPUT_DEB"

  sudo dpkg -i --force-overwrite "$OUTPUT_DEB"
  sudo ldconfig
}

# === Execution ===

if [[ "$BUILD_ALL" == true ]]; then
  build_all_workspace
elif [[ -n $SINGLE_PKG ]]; then
  build_package "$SINGLE_PKG"
else
  PKGS=$(cat "$SCRIPTPATH/../config/$ROS_DISTRO/wolf_list.txt" | grep -v \#)
  for PKG in $PKGS; do
    build_package "$PKG" || {
      echo "Skipping $PKG due to errors."
    }
  done
fi

echo "Debian packages generated successfully in $SCRIPTPATH/../debs/$BRANCH/$OS_VERSION."

