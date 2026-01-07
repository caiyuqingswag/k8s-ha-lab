#!/bin/bash

set -e

DOCKER_VERSION="24.0.6"
DAEMON_JSON="/etc/docker/daemon.json"

echo "==> Installing docker-ce ${DOCKER_VERSION}"
yum install -y docker-ce-${DOCKER_VERSION}*

echo "==> Enable and start docker"
systemctl daemon-reload
systemctl enable --now docker

echo "==> Configure docker daemon.json"
mkdir -p /etc/docker

cat > "$DAEMON_JSON" <<EOF
{
  "registry-mirrors": [
    "https://a88uijg4.mirror.aliyuncs.com",
    "https://docker.lmirror.top",
    "https://docker.m.daocloud.io",
    "https://hub.uuuadc.top",
    "https://docker.anyhub.us.kg",
    "https://dockerhub.jobcher.com",
    "https://dockerhub.icu",
    "https://docker.ckyl.me",
    "https://docker.awsl9527.cn",
    "https://docker.laoex.link"
  ],
  "insecure-registries": [
    "192.168.40.62",
    "harbor"
  ],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

echo "==> Restart docker to apply config"
systemctl restart docker

echo "==> Docker installation completed"
