#!/bin/bash
set -e

########################################
# 全局变量
########################################
K8S_VERSION="1.34.2"
IMAGE_REPO="registry.cn-hangzhou.aliyuncs.com/google_containers"
PAUSE_IMAGE="registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.9"

########################################
# 0. 系统检查
########################################
echo "==> Check OS"
cat /etc/os-release
echo "Kernel: $(uname -r)"

if ! grep -qi "rocky linux 9" /etc/os-release; then
  echo "ERROR: This script is only for Rocky Linux 9"
  exit 1
fi

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
  conntrack-tools \
  ipvsadm \
  socat \
  chrony \
  yum-utils

########################################
# 2. 系统基础设置
########################################
echo "==> Configure system"

# SELinux
setenforce 0 || true
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

# Swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Firewalld（学习环境直接关闭）
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
# 4. 时间同步
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
# 5. 安装 containerd（Docker 官方源）
########################################
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

########################################
# 6. 安装 Kubernetes 组件
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
# 7. 预拉取 Kubernetes 镜像
########################################
echo "==> Pull Kubernetes images"

kubeadm config images pull \
  --kubernetes-version=${K8S_VERSION} \
  --image-repository=${IMAGE_REPO}

########################################
# 完成
########################################
echo "================================================="
echo " Rocky Linux 9.7 Kubernetes 节点初始化完成"
echo "================================================="
echo " 已完成"
echo "   - containerd（systemd cgroup）"
echo "   - kubelet / kubeadm / kubectl ${K8S_VERSION}"
echo "   - 关闭 swap / SELinux"
echo "   - 内核参数 & IPVS"
echo
echo " 下一步"
echo "   Master 节点： kubeadm init"
echo "   Worker 节点：

