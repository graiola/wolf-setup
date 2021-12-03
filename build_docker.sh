#!/bin/bash

UBUNTU=$(lsb_release -cs)

docker build --tag wolf:$UBUNTU .

docker tag wolf:$UBUNTU serger87/wolf:$UBUNTU

docker push serger87/wolf:$UBUNTU
