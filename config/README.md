# Dependecies

To add new dependencies you can modify the files `ros_deps_list.txt` and `sys_deps_list.txt`.
These files contain the list of packages necessary to run the wbc.

# Rosdep Setup

 In order to create the debian packages with bloom, we need to setup rosdep frist. Append the wbc sources with the following command:
 
`sudo echo "yaml http://localhost/wbc.yaml" >> /etc/ros/rosdep/sources.list.d/20-default.list `
 
 Install the apache server:
 
 `sudo apt-get update && sudo apt-get install -y apache2`

Move the wbc.yaml file to the apache server:

`sudo cp wbc.yaml /var/www/html/`

You can now debianize the packages!
