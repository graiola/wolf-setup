#!/bin/bash

docker build --tag wbc:latest .

docker push serger87/wbc:latest
