#!/bin/bash
set -e
source ./00-env.sh

echo "==> Install containerd"

dnf config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

dnf install -y containerd

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
  /etc/containerd/config.toml

sed -i "s|sandbox_image = .*|sandbox_image = \"${PAUSE_IMAGE}\"|" \
  /etc/containerd/config.toml

systemctl daemon-reload
systemctl enable --now containerd

containerd --version
