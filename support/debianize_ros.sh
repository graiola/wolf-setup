#!/bin/bash

# Source helper functions and styles
SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTPATH/fun.cfg"

# Defaults
BRANCH=devel
ROS_WS=ros_ws
ROS_DISTRO=noetic
SINGLE_PKG=
USE_BLOOM=false

USAGE="Usage: debianize [OPTIONS...]
  -b, --branch       Branch to install (default: devel)
  -w, --workspace    Workspace to debianize (default: ros_ws)
  -p, --pkg          Build only one package by name
  -u, --use-bloom    Use bloom to generate .deb (default: false)
  -h, --help         Show this help message"

# Parse arguments
while [ -n "$1" ]; do
  case "$1" in
    -b|--branch) BRANCH="$2"; shift ;;
    -w|--workspace) ROS_WS="$2"; shift ;;
    -p|--pkg) SINGLE_PKG="$2"; shift ;;
    -u|--use-bloom) USE_BLOOM=true ;;
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
  noble) ROS_DISTRO=one ;;
  *) print_error "Unsupported Ubuntu version: $OS_VERSION"; exit 1 ;;
esac

# Source ROS
unset ROS_PACKAGE_PATH
source "/opt/ros/$ROS_DISTRO/setup.bash"
[[ -f "$HOME/$ROS_WS/install/setup.bash" ]] && source "$HOME/$ROS_WS/install/setup.bash"

# Clean previous builds
clean_file "$SCRIPTPATH/../debs/wolf.zip"
clean_folder "$SCRIPTPATH/../debs/$BRANCH"

# === BLOOM BUILD ===
function build_bloom() {
  [[ ! -f package.xml ]] && { print_warn "No package.xml in $(pwd)"; return 1; }

  rosdep install --from-paths . --ignore-src -r -y || return 1
  bloom-generate rosdebian --os-name ubuntu --os-version "$OS_VERSION" --ros-distro "$ROS_DISTRO" --skip-rosdep || return 1

  {
    echo -e "override_dh_usrlocal:"
    echo -e "override_dh_shlibdeps:"
    echo -e "\tdh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info"
  } >> debian/rules

  fakeroot debian/rules binary || return 1
  sudo dpkg -i ../*.deb || return 1

  mkdir -p "$SCRIPTPATH/../debs/$BRANCH/$OS_VERSION"
  mv ../*.deb "$SCRIPTPATH/../debs/$BRANCH/$OS_VERSION"
  rm -rf debian obj-*
}

# === MANUAL BUILD ===
function build_manual() {
  local PKG_NAME="$1"
  local PKG_PATH

  source "/opt/ros/$ROS_DISTRO/setup.bash"

  PKG_PATH=$(rospack find "$PKG_NAME" 2>/dev/null)
  [[ -z "$PKG_PATH" ]] && PKG_PATH=$(find "$HOME/$ROS_WS/src" -type d -name "$PKG_NAME" | head -n1)
  [[ -z "$PKG_PATH" ]] && { print_warn "Package '$PKG_NAME' not found."; return 1; }

  cd "$PKG_PATH" || return 1
  VERSION=$(grep -oPm1 "(?<=<version>)[^<]+" package.xml)
  [[ -z "$VERSION" ]] && VERSION="0.1.0"

  # Clean install/build output
  cd "$HOME/$ROS_WS"
  rm -rf install devel build
  catkin clean -y --yes
  catkin config --install
  catkin build "$PKG_NAME" --no-deps --cmake-args -DCMAKE_BUILD_TYPE=Release || return 1

  # === DEPENDENCY RESOLUTION ===
  local UNCONDITIONAL_DEPENDS=""
  local RAW_DEPENDS
  RAW_DEPENDS=$(xmllint --xpath '//depend[not(@condition)]/text()' "$PKG_PATH/package.xml" 2>/dev/null | tr ' ' '\n')

  for dep in $RAW_DEPENDS; do
    [[ -n "$dep" && "$dep" != "roscpp" ]] && UNCONDITIONAL_DEPENDS+=" ros-${ROS_DISTRO}-$(echo "$dep" | tr '_' '-')"
  done

  local CONDITIONAL_DEPENDS
  RESOLVED_DEPENDS=""
  CONDITIONAL_XML=$(xmllint --format "$PKG_PATH/package.xml" 2>/dev/null | grep -oP '<depend[^>]*condition="[^"]+"[^>]*>[^<]+</depend>')

  while read -r line; do
    DEP=$(echo "$line" | sed -n 's/.*>\(.*\)<.*/\1/p' | xargs)
    if [[ -n "$DEP" ]]; then
      if rospack find "$DEP" &>/dev/null; then
        [[ "$DEP" != "roscpp" ]] && RESOLVED_DEPENDS+=" ros-${ROS_DISTRO}-$(echo "$DEP" | tr '_' '-')"
      fi
    fi
  done <<< "$CONDITIONAL_XML"

  local ALL_DEPENDS
  ALL_DEPENDS=$(echo "$UNCONDITIONAL_DEPENDS $RESOLVED_DEPENDS" | xargs | tr ' ' ', ')

  # === .deb PACKAGE GENERATION ===
  local PKG_DEB_NAME="ros-${ROS_DISTRO}-$(echo "$PKG_NAME" | tr '_' '-')"
  local INSTALL_DIR="$HOME/$ROS_WS/install"
  local DEB_DIR="$HOME/$ROS_WS/debbuild/$PKG_NAME"
  local OUTPUT_DEB="${SCRIPTPATH}/../debs/$BRANCH/$OS_VERSION/${PKG_DEB_NAME}_${VERSION}_${OS_VERSION}_amd64.deb"

  mkdir -p "$(dirname "$OUTPUT_DEB")"
  rm -rf "$DEB_DIR"
  rm -f "$OUTPUT_DEB"
  mkdir -p "$DEB_DIR/DEBIAN" "$DEB_DIR/opt/ros/$ROS_DISTRO"
  cp -a "$INSTALL_DIR"/* "$DEB_DIR/opt/ros/$ROS_DISTRO/"

  cat <<EOF > "$DEB_DIR/DEBIAN/control"
Package: $PKG_DEB_NAME
Version: $VERSION
Section: misc
Priority: optional
Architecture: amd64
Maintainer: ROS Maintainers <ros@ros.org>
Depends: ${ALL_DEPENDS}
Description: Auto-generated .deb for ROS package $PKG_NAME
EOF

  print_info "Building $PKG_NAME"
  print_info "Unconditional: $UNCONDITIONAL_DEPENDS"
  print_info "Conditional:   $RESOLVED_DEPENDS"
  print_info "Dependencies:  $ALL_DEPENDS"

  dpkg-deb --build "$DEB_DIR" "$OUTPUT_DEB"
  rm -rf "$DEB_DIR"
  print_info "✔ Built $OUTPUT_DEB"

  sudo dpkg -i --force-overwrite "$OUTPUT_DEB"
}

# === EXECUTION ===
if $USE_BLOOM; then
  print_info "Using bloom to build packages"
  sudo apt-get update && sudo apt-get install -y python3-bloom fakeroot

  if [[ -n "$SINGLE_PKG" ]]; then
    roscd "$SINGLE_PKG" && build_bloom
  else
    PKG_LIST="$SCRIPTPATH/../config/$ROS_DISTRO/wolf_list.txt"
    [[ ! -f "$PKG_LIST" ]] && { print_error "Missing package list: $PKG_LIST"; exit 1; }

    while read -r PKG; do
      [[ "$PKG" =~ ^#.*$ || -z "$PKG" ]] && continue
      roscd "$PKG" && build_bloom || print_warn "Build failed for $PKG"
    done < "$PKG_LIST"
  fi
else
  print_info "Using manual packaging (no bloom)"
  sudo apt-get update && sudo apt-get install -y libxml2-utils

  if [[ -n "$SINGLE_PKG" ]]; then
    build_manual "$SINGLE_PKG"
  else
    PKG_LIST="$SCRIPTPATH/../config/$ROS_DISTRO/wolf_list.txt"
    [[ ! -f "$PKG_LIST" ]] && { print_error "Missing package list: $PKG_LIST"; exit 1; }

    while read -r PKG; do
      [[ "$PKG" =~ ^#.*$ || -z "$PKG" ]] && continue
      build_manual "$PKG"
    done < "$PKG_LIST"
  fi
fi

