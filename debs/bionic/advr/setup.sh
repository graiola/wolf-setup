# setup env
# TBD NO HARDCODED PREFIX PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/xbot/lib
export CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH:/opt/xbot
export PATH=$PATH:/opt/xbot/bin
export GAZEBO_PLUGIN_PATH=$GAZEBO_PLUGIN_PATH:/opt/xbot/lib
export PYTHONPATH=$PYTHONPATH:/opt/xbot/lib/python2.7/dist-packages:/opt/xbot/lib/python3/dist-packages
export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:/opt/xbot/share:/opt/xbot/lib
mkdir -p $HOME/.xbot
touch $HOME/.xbot/active_config
export XBOT_CONFIG=$HOME/.xbot/active_config
