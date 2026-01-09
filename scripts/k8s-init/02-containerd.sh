#!/bin/bash
set -e
source ./00-env.sh
echo "==> Install containerd"

########################################
# 1. 安装 containerd
########################################
dnf config-manager --add-repo \
  https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

dnf install -y containerd

########################################
# 2. 配置 containerd
########################################
mkdir -p /etc/containerd
mkdir -p /etc/containerd/conf.d

if [ -f /etc/containerd/config.toml ]; then
  cp /etc/containerd/config.toml \
     /etc/containerd/config.toml.bak.$(date +%F-%T)
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "${SCRIPT_DIR}/config.toml" /etc/containerd/config.toml

########################################
# 2.1 写入镜像加速配置（containerd v3 结构）
########################################
cat >/etc/containerd/conf.d/registry-mirrors.toml <<'EOF'
version = 2

[plugins."io.containerd.cri.v1.images".registry.mirrors]

  [plugins."io.containerd.cri.v1.images".registry.mirrors."docker.io"]
    endpoint = [
      "https://docker.m.daocloud.io",
      "https://ccr.ccs.tencentyun.com",
      "https://docker.1ms.run",
      "https://dhub.kubesre.xyz",
      "https://docker.kejilion.pro",
      "https://docker.xuanyuan.me",
      "https://docker.hlmirror.com",
      "https://docker.melikeme.cn"
    ]

  [plugins."io.containerd.cri.v1.images".registry.mirrors."registry.k8s.io"]
    endpoint = [
      "https://docker.m.daocloud.io",
      "https://ccr.ccs.tencentyun.com",
      "https://docker.1ms.run",
      "https://dhub.kubesre.xyz",
      "https://docker.kejilion.pro",
      "https://docker.xuanyuan.me",
      "https://docker.hlmirror.com",
      "https://docker.melikeme.cn"
    ]

  [plugins."io.containerd.cri.v1.images".registry.mirrors."gcr.io"]
    endpoint = ["https://docker.m.daocloud.io"]

  [plugins."io.containerd.cri.v1.images".registry.mirrors."ghcr.io"]
    endpoint = ["https://docker.m.daocloud.io"]

  [plugins."io.containerd.cri.v1.images".registry.mirrors."quay.io"]
    endpoint = ["https://docker.m.daocloud.io"]
EOF

########################################
# 3. crictl 配置
########################################
cat >/etc/crictl.yaml <<'EOF'
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
timeout: 10
debug: false
EOF

########################################
# 4. journald 日志轮换
########################################
echo "==> Configure journald log rotation"

mkdir -p /etc/systemd/journald.conf.d

cat >/etc/systemd/journald.conf.d/99-k8s.conf <<'EOF'
[Journal]
Storage=persistent
Compress=yes

SystemMaxUse=1G
SystemKeepFree=2G
SystemMaxFileSize=100M
SystemMaxFiles=10

MaxRetentionSec=30day
MaxFileSec=7day
EOF

systemctl restart systemd-journald

########################################
# 5. 启动 containerd
########################################
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now containerd

containerd --version

echo "✅ containerd 安装完成 + 镜像加速已配置"
