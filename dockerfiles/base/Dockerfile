ARG IMAGE

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

RUN ./install.sh -i base
