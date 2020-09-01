#!/bin/bash

docker build --tag wbc:latest .

docker tag wbc:latest serger87/wbc:latest

docker push serger87/wbc:latest
