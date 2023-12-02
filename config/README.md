# Dependecies

To add new dependencies you can modify the files `ros_deps_list.txt` and `sys_deps_list.txt`.
These files contain the list of packages necessary to run the WoLF.

# Rosdep Setup

## Local server:

In order to create the debian packages with bloom, we need to setup rosdep frist. Append the wolf sources with the following command:
 
`sudo echo "yaml http://localhost/wolf.yaml" >> /etc/ros/rosdep/sources.list.d/20-default.list `
 
Install the apache server:
 
`sudo apt-get update && sudo apt-get install -y apache2`

Move the wolf.yaml file to the apache server:

`sudo cp wolf.yaml /var/www/html/`

## Github:

`sudo echo "yaml https://raw.githubusercontent.com/graiola/wolf-setup/master/config/wolf.yaml" >> /etc/ros/rosdep/sources.list.d/20-default.list `

# OCS2

This is a short guide on how to create a ocs2 package with only the necessary deps:

```
# Install dependencies
sudo apt install liburdfdom-dev liboctomap-dev libassimp-dev ros-${ROS_DISTRO}-pinocchio ros-${ROS_DISTRO}-hpp-fcl checkinstall
# Clone OCS2 
git clone git@github.com:graiola/ocs2.git
# Clone ocs2_robotic_assets
git clone https://github.com/graiola/ocs2_robotic_assets.git
```

Compile only the necesary ocs2 packages:

```
catkin_make -DCATKIN_WHITELIST_PACKAGES="ocs2_legged_robot_ros;ocs2_self_collision_visualization" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/ocs2
```

Use checkinstall in the catkin build folder:

```
sudo checkinstall --pkgname=wolf_ocs2 --pkgversion=1.0.0 --pkgarch=amd64 -y
```
