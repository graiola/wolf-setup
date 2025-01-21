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
if [[  -z "$ROS_DISTRO_OPT" ]]; then
    if [[ "$UBUNTU" == "jammy" ]]; then
        ROS_DISTRO_OPT="humble"
    elif [[ "$UBUNTU" == "focal" ]]; then
        ROS_DISTRO_OPT="noetic"
    else
        print_warn "Unsupported Ubuntu version! Only 20.04 (focal) and 22.04 (jammy) are supported."
        exit 1
    fi
fi

print_info "Selected ROS distro option: $ROS_DISTRO_OPT"
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
*)
    print_warn "Unsupported ROS distro! Only noetic, foxy, and humble are supported."
    exit 1
    ;;
esac

# Install base components
if [[ "$INSTALL_OPT" == "base" || "$INSTALL_OPT" == "all" ]]; then
    sudo apt install software-properties-common
    sudo add-apt-repository universe
    sudo add-apt-repository restricted
    sudo add-apt-repository multiverse
    sudo sh -c 'echo "deb http://packages.ros.org/${ROS_VERSION_NAME}/ubuntu $(lsb_release -sc) main" | sudo tee $LIST_FILE'
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
    #echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/${ROS_VERSION_NAME}/ubuntu $(lsb_release -cs) main" | sudo tee "$LIST_FILE"
    #wget -qO - https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | sudo tee /usr/share/keyrings/ros-archive-keyring.gpg
    sudo apt-get update
    print_info "Installing system libraries..."
    grep -v '#' "$SCRIPTPATH/config/${ROS_VERSION_NAME}/sys_deps_list.txt" | xargs sudo apt-get install -y
    print_info "Installing Python libraries..."
    grep -v '#' "$SCRIPTPATH/config/${ROS_VERSION_NAME}/python_deps_list.txt" | xargs printf -- "${PYTHON_NAME}-%s\n" | xargs sudo apt-get install -y
    print_info "Installing ROS packages..."
    grep -v '#' "$SCRIPTPATH/config/${ROS_VERSION_NAME}/ros_deps_list.txt" | xargs printf -- "ros-${ROS_DISTRO}-%s\n" | xargs sudo apt-get install -y
    sudo ldconfig
    sudo rosdep init || true
    rosdep update
fi

# Install application components
if [[ "$INSTALL_OPT" == "app" || "$INSTALL_OPT" == "all" ]]; then
    /bin/bash "$SCRIPTPATH/support/get_debians.sh"
    print_info "Installing WoLF debian packages..."
    sudo dpkg -i --force-overwrite "$SCRIPTPATH/debs/$BRANCH_OPT/$UBUNTU/"*.deb
fi

# Update Bashrc
for LINE in "/opt/ros/${ROS_DISTRO}/setup.bash" "/opt/ocs2/setup.sh" "export XBOT_ROOT=/opt/ros/${ROS_DISTRO}"; do
    if ! grep -Fwq "$LINE" ~/.bashrc; then
        print_info "Adding $LINE to .bashrc"
        echo "$LINE" >> ~/.bashrc
    else
        print_info "$LINE is already in .bashrc"
    fi
done
