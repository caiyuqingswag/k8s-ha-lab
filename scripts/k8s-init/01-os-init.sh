#!/bin/bash
set -e
source ./00-env.sh
echo "================================================="
echo " Rocky Linux 9.7 - Kubernetes Node Bootstrap"
echo "================================================="

########################################
# 基础包
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
  conntrack-tools \
  ipvsadm \
  socat \
  chrony \
  yum-utils

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

# Firewalld
systemctl disable --now firewalld || true

########################################
# 内核模块
########################################
echo "==> Configure kernel modules"

cat >/etc/modules-load.d/k8s.conf <<'EOF'
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF

for m in br_netfilter ip_vs ip_vs_rr ip_vs_wrr ip_vs_sh nf_conntrack; do
  modprobe $m || true
done

########################################
# nf_conntrack hashsize（必须在 modprobe 前后都安全）
########################################
echo "==> Configure nf_conntrack hashsize"

cat >/etc/modprobe.d/nf_conntrack.conf <<'EOF'
options nf_conntrack hashsize=65536
EOF

########################################
# sysctl（Kubernetes 生产推荐集）
########################################
echo "==> Configure sysctl"

cat >/etc/sysctl.d/99-kubernetes.conf <<'EOF'
# -------------------------------------------------
# Kubernetes networking
# -------------------------------------------------
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                = 1

# -------------------------------------------------
# Conntrack
# -------------------------------------------------
net.netfilter.nf_conntrack_max = 262144

# -------------------------------------------------
# Network queue & backlog
# -------------------------------------------------
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 16384

# -------------------------------------------------
# TCP tuning
# -------------------------------------------------
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15

# TCP keepalive (prevent stale connections)
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 10

# -------------------------------------------------
# File descriptors
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

sed -ri 's/^#?DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1048576/' /etc/systemd/system.conf || true

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
#####################################
