#!/bin/bash
set -e
source ./00-env.sh
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
# 预拉取镜像
########################################
echo "==> Pull Kubernetes images"

kubeadm config images pull \
  --kubernetes-version=${K8S_VERSION} \
  --image-repository=${IMAGE_REPO}
