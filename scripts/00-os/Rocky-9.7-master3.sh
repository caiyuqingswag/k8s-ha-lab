#!/bin/bash
set -e

########################################
# 变量（只保留版本）
########################################
K8S_VERSION="1.34.2"
IMAGE_REPO="registry.cn-hangzhou.aliyuncs.com/google_containers"

########################################
# 0. 系统检查
########################################
echo "==> Check OS"
cat /etc/os-release
echo "Kernel: $(uname -r)"

########################################
# 1. 基础工具
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
  conntrack \
  ipvsadm \
  socat \
  chrony \
  yum-utils

########################################
# 2. 系统基础设置
########################################
echo "==> Configure system"

setenforce 0 || true
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

systemctl disable --now firewalld || true

########################################
# 3. 内核模块 & sysctl
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

modprobe br_netfilter
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe nf_conntrack

cat >/etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                = 1
EOF

sysctl --system

########################################
# 4. 时间同步（chrony）
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

########################################
# 5. 安装 containerd（Rocky 9 官方源，1.7.x）
########################################
echo "==> Install containerd"

dnf install -y containerd

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
  /etc/containerd/config.toml

sed -i 's|sandbox_image = .*|sandbox_image = "registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.9"|' \
  /etc/containerd/config.toml

systemctl daemon-reload
systemctl enable --now containerd

echo "containerd version:"
containerd --version

########################################
# 6. 安装 Kubernetes 组件（master 必须有）
########################################
echo "==> Install Kubernetes ${K8S_VERSION}"

cat >/etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.34/rpm/
enabled=1
gpgcheck=0
EOF

dnf clean all
dnf makecache -y

dnf install -y \
  kubelet-${K8S_VERSION} \
  kubeadm-${K8S_VERSION} \
  kubectl-${K8S_VERSION}

systemctl enable kubelet

########################################
# 7. 预拉取 Kubernetes 镜像（给 init 用）
########################################
echo "==> Pull Kubernetes images"

kubeadm config images pull \
  --kubernetes-version=${K8S_VERSION} \
  --image-repository=${IMAGE_REPO}

########################################
# 完成提示
########################################
echo "================================================="
echo " Rocky Linux 9.7 Master 节点准备完成"
echo
echo " 本机状态："
echo "   - 可作为 master1 / master2 / master3"
echo "   - 已安装 containerd / kubelet / kubeadm / kubectl"
echo "   - 已预拉取 Kubernetes ${K8S_VERSION} 镜像"
echo
echo " 下一步（你稍后手动做）："
echo "   - 在 master1 上执行 kubeadm init"
echo "   - 在 master2 / master3 上执行 kubeadm join"
echo "================================================="