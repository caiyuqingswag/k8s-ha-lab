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


echo "================================================="
echo " Kubernetes 集群初始化与节点加入说明"
echo "================================================="
echo
echo "【一】初始化第一个控制平面节点（master1）"
echo
echo "请在 master1 节点执行以下命令初始化集群："
echo
echo "  kubeadm init --config=kubeadm.yaml"
echo
echo "初始化成功后，请立即执行以下命令配置 kubectl 访问权限："
echo
echo "  mkdir -p \$HOME/.kube"
echo "  cp /etc/kubernetes/admin.conf \$HOME/.kube/config"
echo "  chown \$(id -u):\$(id -g) \$HOME/.kube/config"
echo
echo "-------------------------------------------------"
echo
echo "【二】生成工作节点（worker / node）加入命令（在 master1 上执行）"
echo
echo "请在 master1 上执行以下命令，获取最新的 worker 节点 join 命令："
echo
echo "  kubeadm token create --print-join-command"
echo
echo "该命令输出的 join 命令仅用于工作节点（worker）。"
echo
echo "-------------------------------------------------"
echo
echo "【三】加入其他控制平面节点（master）"
echo
echo "在其他 master 节点上加入集群前，请先在 master1 上执行："
echo
echo "  kubeadm init phase upload-certs --upload-certs"
echo
echo "命令执行完成后，会输出包含证书密钥的 join 命令。"
echo
echo "请在其他 master 节点上使用该 join 命令，并确保包含参数："
echo
echo "  --control-plane"
echo
echo "================================================="
