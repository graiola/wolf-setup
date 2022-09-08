# Change Log
All notable changes to this project will be documented in this file.
 
The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## wolf_controller - [0.1.3]

### Added
- imu accelerometer filter and rqt interface

### Changed
- function naming inside state estimator to reflect the same functions in wolf_estimation

### Fixed
- bug about imu angular accelerations in wolf_gazebo_interface


## wolf_controller - [0.1.2]

### Added
- clean trajectory waypoints if control mode is changed
- clean waypoints if control mode is changed
- wolf_msgs

### Changed
- robot_semantic_description changed to robot_description_semantic to be compliant with MoveIt!
 
### Fixed
- ramp up the desired joint position instead of the desired torques when standing up
- support polygon scaling inside push recovery
- make rt_gui dependency optional in package.xml

## wolf_controller - [0.1.1]

### Added
- isFirstStep and isLastStep in gait_generator
- export activate_com_z, activate_angular_momentum, activate_postural, activate_joint_position_limits, regularization
- add the possibility to activate the postural, com height control, angular momentum and joint position limits
- joint position limits
- trajectory interpolation and waypoints for the cartesian tasks

### Changed
- update odomPublisher to use tf2 instead of tf
- reduce torque limits to 0.9 in the solver for safety
 
### Fixed 
- avoid publishing duplicated transforms in the odomPublisher, this solves the "Warning: TF_REPEATED_DATA" issue
- fix state_estimator estimation_t deduction from string and vice-versa
- avoid segfault when activating cost
- fix reference frame for the foot tasks
- fix regularization for point contact model
 
## wolf_controller - [0.1.0]

### Added
- Set default_step_reflex_max_retraction value to set the maximum step retraction when the step
  reflex is active

### Changed
 
### Fixed

## wolf_controller - [0.0.9]

### Added
- Mux with priorities
- Spacemouse support

### Changed
 
### Fixed

## wolf_controller - [0.0.8]

### Added
- License

### Changed
 
### Fixed

## wolf_controller - [0.0.7]

### Added
- activate push recovery and step reflex in the param files
- plot capture point information with RVIZ
- add option to integrate floating base velocities in the state estimator

### Changed
- send input device commands only if the robot is in the active state
- push recovery based on capture point
- integrated other services in the keyboard node
 
### Fixed
- angular velocities bug
- arm startup problem

## wolf_controller - [0.0.6]

### Added
- base_footprint [REP-120](https://www.ros.org/reps/rep-0120.html#base-footprint)
- add controller test with EIGEN MALLOC checks
- step reflex
- separate sliders for the velocities

### Changed
- reorganized foot trajectory files
 
### Fixed
- perform init() only one time

## wolf_controller - [0.0.5]

### Added
- new ROS services (reset_base, set_swing_frequency, etc...)
- new ROS services to the keyboard node

### Changed
- working on issue #2
- clean the ros topics
- reduce xbot logger verbosity
- cleaned up various branches
 
### Fixed
- bug fix in the foothold reset about the terrain estimation

## wolf_controller - [0.0.4]

### Added

### Changed
- submodules

### Fixed

## wolf_controller - [0.0.3]

### Added
- first implementation of the push recovery

### Changed
- support for ubuntu 20.04

### Fixed

## wolf_controller - [0.0.2]

### Added

### Changed
- support for ubuntu 18.04
- control stack

### Fixed

## wolf_controller - [0.0.1]

### Added
- init
- arm support

### Changed

### Fixed
