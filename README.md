## Whole body controller with inverse dynamics

This repo contains the debian packages of the whole body controller presented in the following paper: 

    @article{raiola20frontiers,
	author  = {G. Raiola, E. Mingo Hoffman, M. Focchi, N. Tsagarakis, C. Semini.},
	title   = {A simple yet effective whole-body locomotion framework for quadruped robots},
	journal = {Frontiers in Robotics.}
	year    = {2020},
	doi     = {ToDo},
	url     = {ToDo}
    }

## How to run the code

You can run the code either by installing it on your machine, or by running it in a docker container.

### Docker container for Ubuntu 16.04 and 18.04

First you need docker running on your computer. If you need to install docker from scratch, run the following script:

`./install_docker.sh`

Note: it could be necessary to restart the computer after the installation.

When docker is ready and running you can pull the docker image from [docker-hub](https://hub.docker.com/):

+ Run `docker pull serger87/wbc:latest` to download the latest image.
+ Run `docker tag serger87/wbc:latest wbc` to rename the image.
+ Finally you can launch the controller in the docker environment: `./run_docker.sh`

You can see the avaialbe options with `./run_docker.sh --help`

Note: use the `install_nvidia.sh` script if you are experiencing the following problem: `could not select device driver "" with capabilities: [[gpu]]`.

### System installation for Ubuntu 18.04

To install the required dependencies (including ROS) and the wbc debian packages for Ubuntu 18.04 run the following:

`./install_dependencies.sh`

To launch the controller:

`roslaunch wb_controller wb_controller_bringup.launch`

## How to start the controller

To move the robot around you need a joypad plugged in. Press the `start` button when ready. The joypad commands are reported in the image below:

### Joypad commands

![1](docs/joy_commands.png)

## Legal notes

This work is licensed under a [license]("http://creativecommons.org/licenses/by-nc-nd/4.0/") Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License</a>.
![2](https://i.creativecommons.org/l/by-nc-nd/4.0/88x31.png)
