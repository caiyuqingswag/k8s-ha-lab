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

if [ -f /etc/containerd/config.toml ]; then
  cp /etc/containerd/config.toml \
     /etc/containerd/config.toml.bak.$(date +%F-%T)
fi


SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "${SCRIPT_DIR}/config.toml" /etc/containerd/config.toml

cat >/etc/crictl.yaml <<'EOF'
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
timeout: 10
debug: false
EOF


########################################
# 3. journald 日志轮换（containerd / kubelet / systemd）
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

# 立即生效
systemctl restart systemd-journald

########################################
# 4. 启动 containerd
########################################
systemctl daemon-reload
systemctl enable --now containerd

containerd --version
