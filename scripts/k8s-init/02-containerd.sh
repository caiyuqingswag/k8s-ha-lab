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
mkdir -p /etc/containerd/certs.d/docker.io
cat > /etc/containerd/certs.d/docker.io/hosts.toml <<'EOF'
server = "https://docker.io"

[host."https://docker.m.daocloud.io"]
  capabilities = ["pull", "resolve"]

[host."https://ccr.ccs.tencentyun.com"]
  capabilities = ["pull", "resolve"]

[host."https://docker.1ms.run"]
  capabilities = ["pull", "resolve"]

[host."https://dhub.kubesre.xyz"]
  capabilities = ["pull", "resolve"]

[host."https://docker.kejilion.pro"]
  capabilities = ["pull", "resolve"]

[host."https://docker.xuanyuan.me"]
  capabilities = ["pull", "resolve"]

[host."https://docker.hlmirror.com"]
  capabilities = ["pull", "resolve"]

[host."https://docker.melikeme.cn"]
  capabilities = ["pull", "resolve"]
EOF


mkdir -p /etc/containerd/certs.d/registry.k8s.io
cat > /etc/containerd/certs.d/registry.k8s.io/hosts.toml <<'EOF'
server = "https://registry.k8s.io"

[host."https://docker.m.daocloud.io"]
  capabilities = ["pull", "resolve"]

[host."https://ccr.ccs.tencentyun.com"]
  capabilities = ["pull", "resolve"]

[host."https://docker.1ms.run"]
  capabilities = ["pull", "resolve"]

[host."https://dhub.kubesre.xyz"]
  capabilities = ["pull", "resolve"]

[host."https://docker.kejilion.pro"]
  capabilities = ["pull", "resolve"]

[host."https://docker.xuanyuan.me"]
  capabilities = ["pull", "resolve"]

[host."https://docker.hlmirror.com"]
  capabilities = ["pull", "resolve"]

[host."https://docker.melikeme.cn"]
  capabilities = ["pull", "resolve"]
EOF


mkdir -p /etc/containerd/certs.d/gcr.io
cat > /etc/containerd/certs.d/gcr.io/hosts.toml <<'EOF'
server = "https://gcr.io"

[host."https://docker.m.daocloud.io"]
  capabilities = ["pull", "resolve"]
EOF


mkdir -p /etc/containerd/certs.d/ghcr.io
cat > /etc/containerd/certs.d/ghcr.io/hosts.toml <<'EOF'
server = "https://ghcr.io"

[host."https://docker.m.daocloud.io"]
  capabilities = ["pull", "resolve"]
EOF


mkdir -p /etc/containerd/certs.d/quay.io
cat > /etc/containerd/certs.d/quay.io/hosts.toml <<'EOF'
server = "https://quay.io"

[host."https://docker.m.daocloud.io"]
  capabilities = ["pull", "resolve"]
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
