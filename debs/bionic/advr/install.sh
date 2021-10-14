#!/bin/bash

# get path to script and change working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR

# install all binaries
for file in "$PWD"/*.deb; do
  sudo dpkg $1 -i $file
done

# copy environment setup script
sudo cp setup.sh /opt/xbot

# empty .catkin file is needed to find executables
sudo touch /opt/xbot/.catkin
