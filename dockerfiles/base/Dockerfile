ARG IMAGE
ARG ROS

FROM $IMAGE

MAINTAINER Gennaro Raiola <gennaro.raiola@gmail.com>

RUN apt-get -y update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \ 
        apt-utils \ 
        build-essential \
        software-properties-common \
        sudo \
        nano \
        wget \
        git \
        curl \
        openssh-client \
        gpg-agent \
        tzdata \
        cmake-curses-gui \
        xserver-xorg-video-intel \
        libgl1-mesa-glx \
        libgl1-mesa-dri \
        xserver-xorg-core \
        libglu1-mesa-dev \
        freeglut3-dev \
        mesa-common-dev \
        mesa-utils

ADD . /root/

WORKDIR /root/

# Pass ROS argument to the environment
ARG ROS
ENV ROS=$ROS

# Debug the value of ROS
RUN echo "ROS version is: $ROS"

# Use the environment variable in the command
RUN ./install.sh -i base -r $ROS
