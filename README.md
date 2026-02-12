# WoLF: Whole-body Locomotion Framework for quadruped robots

<p align="center">
  <img src="docs/wolf-logo.jpeg" width="250" height="185" />
</p>

This repo contains the setup for the whole-body controller presented in the following papers [raiola2020simple](https://hal.archives-ouvertes.fr/hal-03005133/document), [raiola2022wolf](https://arxiv.org/pdf/2205.06526.pdf): 

```
@article{raiola2020simple,
  title={A simple yet effective whole-body locomotion framework for quadruped robots},
  author={Raiola, Gennaro and Mingo Hoffman, Enrico and Focchi, Michele and Tsagarakis, Nikos and Semini, Claudio},
  journal={Frontiers in Robotics and AI},
  volume={7},
  pages={159},
  year={2020},
  publisher={Frontiers}
}

@article{raiola2022wolf,
  title={WoLF: the Whole-body Locomotion Framework for Quadruped Robots},
  author={Raiola, Gennaro and Focchi, Michele and Hoffman, Enrico Mingo},
  journal={arXiv preprint arXiv:2205.06526},
  year={2022}
}
```

## Features

WoLF provides several features for your quadruped robotic friend:

<div align="center">

|  Push recovery |  Step reflex | Navigation ready  | Loco-manipulation  | Multi robot  |
|:-:|:-:|:-:|:-:|:-:|
|  <img src="docs/push_recovery.gif" width="130" height="70" /> |   <img src="docs/step_reflex.gif" width="130" height="70" />  | <img src="docs/spot_navigation.gif" width="130" height="70" />  | <img src="docs/spot_arm.gif" width="130" height="70" />  | <img src="docs/robots.png" width="120" height="70" />  |

</div>

## Packages

- [wolf-setup](https://github.com/graiola/wolf-setup): This repository, containing scripts and installation utilities for WoLF.
- [wolf_descriptions](https://github.com/graiola/wolf_descriptions): Robot and sensor descriptions used with WoLF.
- [wolf_gazebo_resources](https://github.com/graiola/wolf_gazebo_resources): Gazebo models and simulation resources.
- [wolf_hardware_interface](https://github.com/graiola/wolf_hardware_interface): Hardware interface for `ros_control`.
- [wolf_gazebo_interface](https://github.com/graiola/wolf_gazebo_interface): Gazebo hardware interface for `ros_control`.
- [wolf_controller](https://github.com/graiola/wolf_controller): Main WoLF controller package.
- [wolf_controller_core](https://github.com/graiola/wolf_controller_core): Core libraries for the controller stack.
- [wolf_controller_utils](https://github.com/graiola/wolf_controller_utils): Common controller utilities.
- [wolf_wbid](https://github.com/graiola/wolf_wbid): Whole-body inverse dynamics components.
- [wolf_planner](https://github.com/graiola/wolf_planner): MPC-based planner modules for WoLF.
- [wolf_estimation](https://github.com/graiola/wolf_estimation): Estimation modules (state and perception related).
- [wolf_rviz_plugin](https://github.com/graiola/wolf_rviz_plugin): RViz plugin for WoLF interactions.
- [wolf_msgs](https://github.com/graiola/wolf_msgs): ROS messages and service definitions.
- [rt_logger](https://github.com/graiola/rt_logger): Real-time logging utilities.
- [rt_gui](https://github.com/graiola/rt_gui): Runtime GUI tooling.

## How to run WoLF

You can run WoLF by installing the debian packages on your computer or with a docker container. To clone this repository run the following command:

`git clone https://github.com/graiola/wolf-setup.git`

### Docker container for Ubuntu 16.04 - 18.04 - 20.04

To download the image from [docker-hub](https://hub.docker.com/r/serger87/wolf-app) and launch WoLF within a docker container, run the following script:

`./run_docker.sh`

You can see what are the available options in the script with the following command:

`./run_docker.sh --help`

In case you don't have docker installed on your computer, you can run the following script:

`./support/install_docker.sh`

This script will install docker and its dependencies.

#### Demos:

We prepared some demos to run directly within the docker container:

- `./demos/2d_navigation.sh` : Run an indoor 2D navigation demo 
- `./demos/3d_navigation.sh` : Run an outdoor 3D navigation demo
- `./demos/manipulation.sh` : Run spot with a kinova arm mounted on top
- `./demos/locomotion.sh` : Run a demo with stairs

#### Notes:

- It could be necessary to restart the computer after running `install_docker.sh`.
- Use the `install_nvidia.sh` script in the `support` folder  if you are experiencing the following problem: `could not select device driver "" with capabilities: [[gpu]]`. 
- If you are experiencing this problem `nvidia-container-cli initialization error nvml error driver not loaded`, it probably means that your computer does not have the latest nvidia-drivers installed, so be sure that they are installed and updated to the last version.

### System installation for Ubuntu 20.04

To install the required dependencies (including ROS) and the WoLF debian packages run the following:

`./install.sh`

After the installation, update your bash enviroment with the following command:

`source ~/.bashrc`

#### How to start the controller

WoLF provides four interfaces to move the robot:

- A [PS3](docs/ps3.png) joypad interface: `roslaunch wolf_controller wolf_controller_bringup.launch input_device:=ps3`
- A [XBox](docs/xbox.jpeg) joypad interface: `roslaunch wolf_controller wolf_controller_bringup.launch input_device:=xbox`
- A [keyboard](docs/keyboard.png) interface: `roslaunch wolf_controller wolf_controller_bringup.launch input_device:=keyboard`
- A [spacemouse](docs/spacemouse.pdf) interface: `roslaunch wolf_controller wolf_controller_bringup.launch input_device:=spacemouse`

A twist topic is always active and listening for velocity commands on `/robot_name/wolf_controller/twist`. This topic can be used to send twist commands at a lower priority than the above mentioned interfaces.
It can also be used to send `move_base` commands if you want  to integrate WoLF with the ROS navigation stack (see [wolf_navigation](https://github.com/graiola/wolf_navigation) for an example).
To make the robot stand up, press the `start` button on the joypad or press the `enter` key if you are using the keyboard.

## How to add a new robot

If you want to test a different quadruped robot check out [wolf_descriptions](https://github.com/graiola/wolf_descriptions).

## Changelog

Check the changelog [here](CHANGELOG.md)
