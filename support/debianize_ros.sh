#!/bin/bash

# This script builds .deb packages from ROS packages without using bloom

# Get script path
SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTPATH/fun.cfg"

# Defaults
BRANCH=devel
ROS_WS=ros_ws
ROS_DISTRO=noetic
SINGLE_PKG=

# Help text
USAGE="Usage: debianize [OPTIONS...]
  -b, --branch     Branch to install (default: devel)
  -w, --workspace  Workspace to debianize (default: ros_ws)
  -p, --pkg        Build only one package by name
  -h, --help       Show this help message"

# Parse arguments
while [ -n "$1" ]; do
  case "$1" in
    -b|--branch) BRANCH="$2"; shift ;;
    -w|--workspace) ROS_WS="$2"; shift ;;
    -p|--pkg) SINGLE_PKG="$2"; shift ;;
    -h|--help) echo -e "$USAGE"; exit 0 ;;
    *) echo "Unknown option: $1"; echo -e "$USAGE"; exit 1 ;;
  esac
  shift
done

# Detect Ubuntu version and set ROS_DISTRO accordingly
OS_VERSION=$(lsb_release -cs)
case "$OS_VERSION" in
  focal) ROS_DISTRO=noetic ;;
  jammy) ROS_DISTRO=humble ;;
  *) echo "Unsupported Ubuntu version: $OS_VERSION"; exit 1 ;;
esac

# Set up ROS environment
source /opt/ros/$ROS_DISTRO/setup.bash || exit 1
[[ -f "$HOME/$ROS_WS/devel/setup.bash" ]] && source "$HOME/$ROS_WS/devel/setup.bash"

# Prepare output directory
OUT_DIR="$SCRIPTPATH/../debs/$BRANCH/$OS_VERSION"
mkdir -p "$OUT_DIR"

# Update dependencies
sudo rosdep update
rosdep install --from-paths "$HOME/$ROS_WS/src" --ignore-src -r -y || {
  echo "rosdep install failed"; exit 1;
}

# Function to build a single package
build_pkg() {
  PKG_NAME="$1"
  PKG_PATH=$(rospack find "$PKG_NAME" 2>/dev/null)
  [[ -z "$PKG_PATH" ]] && { echo "Package $PKG_NAME not found"; return 1; }

  cd "$PKG_PATH" || return 1

  # Extract version from package.xml
  VERSION=$(grep -oPm1 "(?<=<version>)[^<]+" package.xml)
  [[ -z "$VERSION" ]] && VERSION="0.1.0"

  # Extract run_depend tags as ROS-style package dependencies
  DEPENDS=$(grep -oPm1 "(?<=<depend>).*?(?=</depend>)" package.xml |
            sed -e 's/_/-/g' -e "s/^/ros-${ROS_DISTRO}-/" |
            paste -sd ', ' -)
  [[ -z "$DEPENDS" ]] && DEPENDS=""

  # Build with catkin
  cd "$HOME/$ROS_WS"
  catkin config --install
  catkin clean -y
  catkin build "$PKG_NAME" --cmake-args -DCMAKE_BUILD_TYPE=Release || return 1

  # Prepare deb package name
  PKG_DEB_NAME="ros-${ROS_DISTRO}-$(echo $PKG_NAME | tr '_' '-')"
  INSTALL_DIR="$HOME/$ROS_WS/install"
  DEB_DIR="$HOME/$ROS_WS/debbuild/$PKG_NAME"
  OUTPUT_DEB="${OUT_DIR}/${PKG_DEB_NAME}_${VERSION}_${OS_VERSION}_amd64.deb"

  # Clean up
  rm -rf "$DEB_DIR"
  rm -f "${OUT_DIR}/${PKG_DEB_NAME}_"*"_amd64.deb"

  # Create structure
  mkdir -p "$DEB_DIR/DEBIAN" "$DEB_DIR/opt/ros/$ROS_DISTRO"
  cp -a "$INSTALL_DIR"/* "$DEB_DIR/opt/ros/$ROS_DISTRO/"

  # Generate control file
  cat <<EOF > "$DEB_DIR/DEBIAN/control"
Package: $PKG_DEB_NAME
Version: $VERSION
Section: misc
Priority: optional
Architecture: amd64
Maintainer: ROS Maintainers <ros@ros.org>
Depends: ${DEPENDS}
Description: Auto-generated .deb for ROS package $PKG_NAME
EOF

  # Build the package
  dpkg-deb --build "$DEB_DIR" "$OUTPUT_DEB"
  rm -rf "$DEB_DIR"
  echo "✔ Built $OUTPUT_DEB"
}


# Build either a single package or a list
if [[ -n "$SINGLE_PKG" ]]; then
  build_pkg "$SINGLE_PKG"
else
  PKG_LIST="$SCRIPTPATH/../config/$ROS_DISTRO/wolf_list.txt"
  [[ ! -f "$PKG_LIST" ]] && { echo "Missing package list: $PKG_LIST"; exit 1; }

  while read -r PKG; do
    [[ "$PKG" =~ ^#.*$ || -z "$PKG" ]] && continue
    build_pkg "$PKG"
  done < "$PKG_LIST"
fi

