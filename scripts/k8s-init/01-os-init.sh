#!/bin/bash
set -euo pipefail

source ./00-env.sh

echo "================================================="
echo " Rocky Linux 9.7 - Kubernetes Node Bootstrap (nftables-only)"
echo "================================================="

########################################
# 基础包（nftables-only，无 IPVS）
########################################
echo "==> Install base packages"

dnf install -y \
  device-mapper-persistent-data \
  lvm2 \
  wget \
  net-tools \
  nfs-utils \
  curl \
  unzip \
  sudo \
  vim \
  bash-completion \
  conntrack-tools \
  socat \
  chrony \
  yum-utils \
  nftables

########################################
# 系统基础设置
########################################
echo "==> Configure system base"

# SELinux
setenforce 0 || true
sed -ri 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

# Swap
swapoff -a
sed -ri '/\sswap\s/s/^/#/' /etc/fstab

# Firewalld（如果你后面要用 nftables 自己管策略，可以关；保持你原逻辑）
systemctl disable --now firewalld || true

########################################
# 内核模块（nftables/k8s 必需最小集）
########################################
echo "==> Configure kernel modules (no IPVS)"

cat >/etc/modules-load.d/k8s.conf <<'EOF'
br_netfilter
nf_conntrack
EOF

for m in br_netfilter nf_conntrack; do
  modprobe "$m" || true
done

########################################
# nf_conntrack hashsize（写入持久化 + 尽量当前生效）
########################################
echo "==> Configure nf_conntrack hashsize"

# 建议值：65536（对应 nf_conntrack_max=262144 比较合理）
cat >/etc/modprobe.d/nf_conntrack.conf <<'EOF'
options nf_conntrack hashsize=65536
EOF

# 尝试运行时设置（注意：部分内核/场景可能不可写或会被忽略，不影响后续）
if [ -e /sys/module/nf_conntrack/parameters/hashsize ]; then
  cur="$(cat /sys/module/nf_conntrack/parameters/hashsize 2>/dev/null || echo "")"
  if [ "$cur" != "65536" ] && [ -n "$cur" ]; then
    echo 65536 > /sys/module/nf_conntrack/parameters/hashsize 2>/dev/null || true
  fi
fi

########################################
# sysctl（Kubernetes 生产推荐集，适配 nftables）
########################################
echo "==> Configure sysctl"

cat >/etc/sysctl.d/99-kubernetes.conf <<'EOF'
# -------------------------------------------------
# Kubernetes networking (required)
# -------------------------------------------------
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                = 1

# -------------------------------------------------
# Conntrack (required for kube-proxy/cni)
# -------------------------------------------------
net.netfilter.nf_conntrack_max = 262144

# -------------------------------------------------
# Network queue & backlog (general tuning)
# -------------------------------------------------
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 16384

# -------------------------------------------------
# TCP tuning (general tuning)
# -------------------------------------------------
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15

# TCP keepalive (prevent stale connections)
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 10

# -------------------------------------------------
# File descriptors (system-wide)
# -------------------------------------------------
fs.file-max = 2097152

# -------------------------------------------------
# inotify (kubelet / containers)
# -------------------------------------------------
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192

# -------------------------------------------------
# Memory map (ES / JVM / CSI)
# -------------------------------------------------
vm.max_map_count = 262144

# -------------------------------------------------
# AIO (database / storage)
# -------------------------------------------------
fs.aio-max-nr = 1048576
EOF

sysctl --system

########################################
# 用户级文件句柄限制
########################################
echo "==> Configure ulimit"

cat >/etc/security/limits.d/90-k8s.conf <<'EOF'
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

########################################
# systemd 级文件句柄（重要）
########################################
echo "==> Configure systemd limits"

# 更推荐 drop-in（比 sed system.conf 更稳）
mkdir -p /etc/systemd/system.conf.d
cat >/etc/systemd/system.conf.d/90-k8s-limits.conf <<'EOF'
[Manager]
DefaultLimitNOFILE=1048576
EOF

# 让 systemd 重新加载配置（对新启动的服务生效）
systemctl daemon-reexec || true

########################################
# 时间同步
########################################
echo "==> Configure chrony"

cat >/etc/chrony.conf <<'EOF'
server ntp1.aliyun.com iburst
server ntp2.aliyun.com iburst
server ntp1.tencent.com iburst
server ntp2.tencent.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
EOF

systemctl enable --now chronyd


########################################
# 完成
########################################
echo "================================================="
echo " Node bootstrap completed (nftables-only baseline)"
echo "================================================="
