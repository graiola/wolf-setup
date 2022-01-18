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



