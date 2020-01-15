#!/bin/bash
# adct - Docker Installation
# https://github.com/ArtiomL/f5-terraform
# Artiom Lichtenstein
# v1.0.0, 31/08/2018

# Core dependencies
sudo apt-get update
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# f5-demo-https workload
docker run --restart unless-stopped --net=host -p 80:80 -p 443:443 -d f5devcentral/f5-demo-httpd

