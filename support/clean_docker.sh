#!/bin/bash

#Clean docker stopped containers, volumes and images
# see: http://stackoverflow.com/questions/32723111/how-to-remove-old-and-unused-docker-images and https://github.com/chadoe/docker-cleanup-volumes

# Stopped containers
docker rm $(docker ps -qa --no-trunc --filter "status=exited")
# Volumes
docker volume rm $(docker volume ls -qf dangling=true)
# Images
docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
docker rmi $(docker images | grep "none" | awk '/ / { print $3 }')
# Registry
docker exec $(docker ps -f "name=registry" --format "{{.ID}}") registry garbage-collect /etc/docker/registry/config.yml

