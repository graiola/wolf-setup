#########################################
#					#
#            WBC-DOCKERED		#
#                                       #
# my github: https://github.com/graiola #
#					#
#########################################

#FROM nvidia/cudagl:11.4.2-base-ubuntu20.04
FROM nvidia/cudagl:9.2-base-ubuntu18.04

MAINTAINER Gennaro Raiola <gennaro.raiola@gmail.com>

RUN apt-get -y update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \ 
	apt-utils \ 
	build-essential \
        software-properties-common \
        sudo \
        wget \
        git \
        openssh-client \
        gpg-agent \
        tzdata \
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

RUN bash install_dependencies.sh
