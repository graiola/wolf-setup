ARG IMAGE
ARG BRANCH

FROM $IMAGE

MAINTAINER Gennaro Raiola <gennaro.raiola@gmail.com>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install dirmngr -y

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
