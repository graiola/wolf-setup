#!/bin/bash

set -e

# Install curl if missing
sudo apt-get update
sudo apt-get install -y curl gnupg ca-certificates

# Define the distribution (e.g. ubuntu22.04)
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)

# Add the NVIDIA GPG key (in modern keyring format)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  gpg --dearmor | sudo tee /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg > /dev/null

# Add the NVIDIA repo using signed-by
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's|^deb |deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] |' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

# Update and install packages
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit-base nvidia-container-runtime

# Restart Docker to apply changes
sudo systemctl restart docker

