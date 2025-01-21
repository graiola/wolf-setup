ARG IMAGE
ARG BRANCH

FROM $IMAGE

MAINTAINER Gennaro Raiola <gennaro.raiola@gmail.com>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install dirmngr -y

# Set velodyne gpus dependencies for gazebo in order to enable the velodyne simulation using the gpu with gazebo:
RUN sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/gazebo-stable.list'
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D2486D2DD83DB69272AFE98867170598AF249743
RUN apt-get -y update && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

ADD . /root/

WORKDIR /root/

# Pass BRANCH argument to the environment
ARG BRANCH
ENV BRANCH=$BRANCH

# Debug the value of BRANCH
RUN echo "BRANCH is: $BRANCH"

# Use the environment variable in the command
RUN ./install.sh -i app -b $BRANCH
