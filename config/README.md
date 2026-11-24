# Dependecies

To add new dependencies you can modify the files:

- `ros_deps_list.txt`
- `sys_deps_list.txt`
- `python_deps_list.txt` for apt-installed Python modules (`python3-<name>`)
- `pip_deps_list.txt` for pip-only Python modules

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

`sudo echo "yaml https://raw.githubusercontent.com/graiola/wolf-setup/master/config/$ROS_VERSION/wolf.yaml" >> /etc/ros/rosdep/sources.list.d/20-default.list `

# ROS 2 MPC

Humble and Jazzy use the embedded solver in `wolf_planner_mpc`. Do not build
OCS2 catkin packages or source `/opt/ocs2/setup.sh` for this migration. Import
the coordinated `wolf_planner/manifests/planner.repos` into a clean workspace;
its repositories are siblings under `src/planner/`. In an existing workspace,
reuse the owning source manifests and checkouts so colcon sees each package once.

The optional `support/build_planner_ros2.sh` helper builds the packages in
`config/<distro>/planner_list.txt` using installed numerical dependencies.
The planner README describes the alternative explicit fetch of pinned
HPIPM/BLASFEO libraries, the compatible Pinocchio/HPP-FCL versions and native
validation. These dependencies remain necessary for the numerical solver;
the external OCS2 package graph does not.

The top-level installer only adds the ROS 2 environment to `.bashrc`. If a
previous installation added a legacy OCS2 source line, use a clean ROS 2 shell
and remove that line from the ROS 2 shell configuration before building.

The perceptive plugin and the ROS 1 terrain packages below are excluded from
the active default/adaptive planner build. See the planner's
`docs/PERCEPTIVE_MIGRATION.md` for their separate port and acceptance gates.

# Legacy ROS 1 OCS2

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
catkin_make -DCATKIN_WHITELIST_PACKAGES="ocs2_thirdparty;ocs2_core;ocs2_legged_robot_ros;ocs2_self_collision_visualization;ocs2_robotic_tools;ocs2_oc;ocs2_pinocchio_interface;ocs2_self_collision;ocs2_ros_interfaces;ocs2_msgs;ocs2_mpc;ocs2_ddp;ocs2_qp_solver;ocs2_sqp;blasfeo_catkin;hpipm_catkin;ocs2_ipm;ocs2_centroidal_model;ocs2_robotic_assets;ocs2_legged_robot" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/ocs2
```

Use checkinstall in the catkin build folder:

```
sudo checkinstall --pkgname=wolf_ocs2 --pkgversion=1.0.0 --pkgarch=amd64 -y
```

# Legacy ROS 1 terrain packages (elevation and terrain estimation)

```
# Clone Packages
git clone git@github.com:graiola/any_node.git
git clone git@github.com:graiola/elevation_mapping.git
git clone git@github.com:graiola/grid_map.git
git clone git@github.com:graiola/kindr.git
git clone git@github.com:graiola/kindr_ros.git
git clone git@github.com:graiola/message_logger.git
git clone git@github.com:graiola/traversability_estimation.git
```

Compile:

```
catkin_make -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/anybotics
```

Use checkinstall in the catkin build folder:

```
sudo checkinstall --pkgname=wolf_anybotics --pkgversion=1.0.0 --pkgarch=amd64 -y
```
