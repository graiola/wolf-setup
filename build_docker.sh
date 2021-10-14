#!/bin/bash

UBUNTU=$(lsb_release -cs)

docker build --tag wbc:$UBUNTU .

docker tag wbc:$UBUNTU serger87/wbc:$UBUNTU

docker push serger87/wbc:$UBUNTU
