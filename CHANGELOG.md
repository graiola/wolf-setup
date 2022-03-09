# Change Log
All notable changes to this project will be documented in this file.
 
The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).
 
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
