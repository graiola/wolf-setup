#!/bin/bash

# Get this script's path
pushd "$(dirname "$0")" > /dev/null
SCRIPTPATH=$(pwd)
popd > /dev/null

set -e

source "$SCRIPTPATH/support/fun.cfg"

USAGE="Usage: \n install [OPTIONS...]
\n\n
Help Options:
\n
-h,--help \tShow help options
\n\n
Application Options:
\n
-i,--install \tInstall options [base|app|all], example: -i all
\n
-b,--branch \tBranch to install, example: -b devel
\n
-r,--ros \tROS distro to install, example: -r noetic"

# Default
INSTALL_OPT="all"
BRANCH_OPT="devel"
ROS_DISTRO_OPT=
PYTHON_NAME="python3"
UBUNTU=$(lsb_release -cs)

wolf_banner

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo -e "$USAGE"
    exit 0
fi

while [[ -n "$1" ]]; do
    case "$1" in
    -i|--install)
        INSTALL_OPT="$2"
        shift
        ;;
    -b|--branch)
        BRANCH_OPT="$2"
        shift
        ;;
    -r|--ros)
        ROS_DISTRO_OPT="$2"
        shift
        ;;
    *)
        print_warn "Option $1 not recognized!"
        echo -e "$USAGE"
        exit 1
        ;;
    esac
    shift
done

# Validate install options
if [[ "$INSTALL_OPT" != "base" && "$INSTALL_OPT" != "app" && "$INSTALL_OPT" != "all" ]]; then
    print_warn "Wrong install option!"
    echo -e "$USAGE"
    exit 1
fi

print_info "Selected install option: $INSTALL_OPT"

# Determine ROS distro
if [[ -z "$ROS_DISTRO_OPT" ]]; then
    case "$UBUNTU" in
        jammy)
            ROS_DISTRO_OPT="humble"
            ;;
        focal)
            ROS_DISTRO_OPT="noetic"
            ;;
        noble)
            ROS_DISTRO_OPT="one"
            ;;
        *)
            print_warn "Unsupported Ubuntu version! Only focal (20.04), jammy (22.04), and noble (24.04) are supported."
            exit 1
            ;;
    esac
fi

print_info "Selected ROS distro option: $ROS_DISTRO_OPT"
print_info "Selected UBUNTU distro option: $UBUNTU"
print_info "Selected BRANCH option: $BRANCH_OPT"

# Set ROS-related variables
case "$ROS_DISTRO_OPT" in
noetic)
    ROS_VERSION_NAME="ros"
    ROS_DISTRO="$ROS_DISTRO_OPT"
    LIST_FILE="/etc/apt/sources.list.d/ros-latest.list"
    ;;
foxy|humble)
    ROS_VERSION_NAME="ros2"
    ROS_DISTRO="$ROS_DISTRO_OPT"
    LIST_FILE="/etc/apt/sources.list.d/ros2.list"
    ;;
one)
    ROS_VERSION_NAME="ros"
    ROS_DISTRO="$ROS_DISTRO_OPT"
    LIST_FILE="/etc/apt/sources.list.d/ros1.list"
    ;;
*)
    print_warn "Unsupported ROS distro! Only noetic, foxy, humble, and one are supported."
    exit 1
    ;;
esac

# Install base components
if [[ "$INSTALL_OPT" == "base" || "$INSTALL_OPT" == "all" ]]; then
    # Define variables
    KEY_FILE="/usr/share/keyrings/ros-archive-keyring.gpg"
    ROS_REPO="http://packages.ros.org/${ROS_VERSION_NAME}/ubuntu"

    # Check if the repository is already added
    if grep -q "${ROS_REPO}" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        print_info "ROS repository is already present. Skipping repository setup."
    else
        print_info "Adding ROS repository..."
        if [[ "$ROS_DISTRO" == "one" ]]; then
            sudo mkdir -p /etc/apt/keyrings
            sudo curl -sSL https://ros.packages.techfak.net/gpg.key -o /etc/apt/keyrings/ros-one-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/ros-one-keyring.gpg] https://ros.packages.techfak.net $(lsb_release -cs) main" | sudo tee "$LIST_FILE"
            echo "# deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/ros-one-keyring.gpg] https://ros.packages.techfak.net $(lsb_release -cs) main-dbg" | sudo tee -a "$LIST_FILE"
        else
            sudo mkdir -p /usr/share/keyrings
            sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | \
                sudo gpg --dearmor -o "$KEY_FILE"
            echo "deb [arch=$(dpkg --print-architecture) signed-by=${KEY_FILE}] ${ROS_REPO} $(lsb_release -cs) main" | \
                sudo tee "$LIST_FILE" > /dev/null
        fi
    fi

    sudo apt-get update

    print_info "Installing system libraries..."
    grep -v '#' "$SCRIPTPATH/config/${ROS_DISTRO}/sys_deps_list.txt" | xargs sudo apt-get install -y

    print_info "Installing Python libraries..."
    grep -v '#' "$SCRIPTPATH/config/${ROS_DISTRO}/python_deps_list.txt" | xargs printf -- "${PYTHON_NAME}-%s\n" | xargs sudo apt-get install -y

    print_info "Installing ROS packages..."
    grep -v '#' "$SCRIPTPATH/config/${ROS_DISTRO}/ros_deps_list.txt" | xargs printf -- "ros-${ROS_DISTRO}-%s\n" | xargs sudo apt-get install -y

    sudo ldconfig
    sudo rosdep init || true
    rosdep update

    if [[ "$ROS_DISTRO" == "one" ]]; then
        echo "yaml https://ros.packages.techfak.net/ros-one.yaml one" | sudo tee /etc/ros/rosdep/sources.list.d/1-ros-one.list
        rosdep update
    fi
fi

# Install application components
if [[ "$INSTALL_OPT" == "app" || "$INSTALL_OPT" == "all" ]]; then
    /bin/bash "$SCRIPTPATH/support/get_debians.sh"
    print_info "Installing WoLF debian packages..."
    sudo dpkg -i --force-overwrite "$SCRIPTPATH/debs/$BRANCH_OPT/$UBUNTU/"*.deb || true
    sudo apt-get install -f -y
fi

# Update Bashrc
for LINE in "source /opt/ros/${ROS_DISTRO}/setup.bash" "source /opt/ocs2/setup.sh" "export XBOT_ROOT=/opt/ros/${ROS_DISTRO}"; do
    if ! grep -Fwq "$LINE" ~/.bashrc; then
        print_info "Adding $LINE to .bashrc"
        echo "$LINE" >> ~/.bashrc
    else
        print_info "$LINE is already in .bashrc"
    fi
done

