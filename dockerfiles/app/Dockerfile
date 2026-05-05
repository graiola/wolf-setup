ARG IMAGE
ARG BRANCH

FROM $IMAGE

MAINTAINER Gennaro Raiola <gennaro.raiola@gmail.com>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install dirmngr -y

# Add the Gazebo package repository used by the Humble/gz simulator stack.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release && \
    mkdir -p /usr/share/keyrings && \
    curl -fsSL https://packages.osrfoundation.org/gazebo.gpg | \
      gpg --dearmor -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "Acquire::Retries \"5\";" > /etc/apt/apt.conf.d/80-retries && \
    echo "Acquire::http::Timeout \"30\";" >> /etc/apt/apt.conf.d/80-retries && \
    echo "Acquire::https::Timeout \"30\";" >> /etc/apt/apt.conf.d/80-retries && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -sc) main" \
      > /etc/apt/sources.list.d/gazebo-stable.list
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
