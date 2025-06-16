#!/bin/bash

#This script uses the system ROS_DISTRO and ubuntu version
#Branch is treated as a folder, so be sure that the git repository is in the correct branch!
#git name-rev --name-only HEAD

# Get this script's path
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null

source "$SCRIPTPATH/fun.cfg"

USAGE="Usage: \n debianize [OPTIONS...]
\n\n
Help Options:
\n 
-h,--help \tShow help options
\n\n
Application Options:
\n 
-b,--branch\tBranch to install, example: -b devel
\n
-w, --workspace\tWorkspace to debianize, example: -w ros_ws
\n
-p, --pkg\tSelect package to compile, example: -p package_name
"

# Default
BRANCH=devel
OS=ubuntu
ROS_WS=ros_ws
ROS_DISTRO=noetic
SINGLE_PKG=

# Help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then 
	echo -e "$USAGE"
	exit 0
fi

# Parse args
while [ -n "$1" ]; do
	case "$1" in
	-b|--branch) BRANCH="$2"; shift ;;
	-w|--workspace) ROS_WS="$2"; shift ;;
	-p|--pkg) SINGLE_PKG="$2"; shift ;;
	*) echo "Option $1 not recognized!"; echo -e "$USAGE"; exit 1 ;;
	esac
	shift
done

# Clean previous builds
clean_file "$SCRIPTPATH/../debs/wolf.zip"
clean_folder "$SCRIPTPATH/../debs/$BRANCH"

# Check Ubuntu version
OS_VERSION=$(lsb_release -cs)
if [[ "$OS_VERSION" == "jammy" ]]; then
	ROS_DISTRO=humble
	PYTHON_NAME=python3
elif [[ "$OS_VERSION" == "focal" ]]; then
	ROS_DISTRO=noetic
	PYTHON_NAME=python3
else
	print_warn "Wrong Ubuntu! This script supports Ubuntu 20.04 (focal) and 22.04 (jammy)"
	exit 1
fi

# Dependencies
sudo apt-get update && sudo apt-get install -y ${PYTHON_NAME}-bloom fakeroot

# Source environments
unset ROS_PACKAGE_PATH
source /opt/ocs2/setup.sh
source /opt/ros/$ROS_DISTRO/setup.bash
source "$HOME/$ROS_WS/install/setup.bash" || {
  echo "Workspace not built or install/setup.bash not found."
  exit 1
}
export CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH:/opt/ocs2/share

print_info "+++++++++++++ ROS:"
echo "$ROS_DISTRO"
echo "$ROS_WS"
print_info "+++++++++++++"

print_info "+++++++++++++ ROS PACKAGE PATH:"
echo "$ROS_PACKAGE_PATH"
print_info "+++++++++++++"

# rosdep update
sudo rosdep fix-permissions
rosdep update

function build() {
    # Ensure we're in a valid ROS package
    if [[ ! -f "package.xml" ]]; then
        print_warn "No package.xml found in $(pwd), skipping."
        return 1
    fi

    # Resolve dependencies
    rosdep install --from-paths . --ignore-src -r -y || {
        print_warn "rosdep failed for $(basename $(pwd))"
        return 1
    }

    # Generate Debian files
    bloom-generate rosdebian --os-name $OS --os-version $OS_VERSION --ros-distro $ROS_DISTRO --skip-rosdep || return 1

    # Patch debian rules
    {
        echo -e "override_dh_usrlocal:"
        echo -e "override_dh_shlibdeps:"
        echo -e "\tdh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info"
    } >> debian/rules

    # Build and move .deb
    fakeroot debian/rules binary || return 1
    sudo dpkg -i ../*.deb || return 1

    mkdir -p "$SCRIPTPATH/../debs/$BRANCH/$OS_VERSION"
    mv ../*.deb "$SCRIPTPATH/../debs/$BRANCH/$OS_VERSION"

    # Clean up
    rm -rf debian obj-*
}

# Build single package or list
if [[ -n "$SINGLE_PKG" ]]; then
    roscd "$SINGLE_PKG" 2>/dev/null || {
        print_warn "Package $SINGLE_PKG not found"
        exit 1
    }
    build
else
    PKG_LIST_FILE="$SCRIPTPATH/../config/$ROS_DISTRO/wolf_list.txt"
    if [[ ! -f "$PKG_LIST_FILE" ]]; then
        echo "Package list not found: $PKG_LIST_FILE"
        exit 1
    fi

    for PKG in $(grep -v '^#' "$PKG_LIST_FILE"); do
        roscd "$PKG" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            echo "Building package: $PKG"
            build || print_warn "Build failed for $PKG"
        else
            print_warn "Package $PKG is not available"
        fi
    done
fi

