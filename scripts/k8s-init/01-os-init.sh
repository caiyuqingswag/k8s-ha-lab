#!/bin/bash
set -e
source ./00-env.sh

echo "==> System update & base packages"

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
echo "==> Configure system"

# SELinux
setenforce 0 || true
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

# Swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Firewalld
systemctl disable --now firewalld || true

########################################
# 内核模块 & sysctl
########################################
echo "==> Configure kernel modules and sysctl"

cat >/etc/modules-load.d/k8s.conf <<EOF
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

cat >/etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                = 1
EOF

sysctl --system

########################################
# 时间同步
########################################
echo "==> Configure chrony"

cat >/etc/chrony.conf <<EOF
server ntp1.aliyun.com iburst
server ntp2.aliyun.com iburst
server ntp1.tencent.com iburst
server ntp2.tencent.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
EOF

systemctl enable --now chronyd

