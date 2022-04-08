#!/bin/bash
set -eo pipefail

# 
# From:
# https://www.atlantic.net/dedicated-server-hosting/how-to-install-and-use-podman-on-ubuntu-20-04/

echo Install Podman dependencies.. >> artifacts/test_artifact.log
sudo apt-get update
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
    build-essential \
    curl \
    wget \
    gnupg2

source /etc/os-release

sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key  
sudo apt-key add Release.key
rm Release.key

sudo apt-get update -qq -y
sudo apt-get -qq --yes install podman

podman --version >> artifacts/test_artifact.log
