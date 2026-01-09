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
echo " Kubernetes 高可用集群初始化与节点加入说明"
echo "================================================="
echo
echo "【一】初始化第一个控制平面节点（master1）"
echo
echo "请在 master1 节点执行："
echo
echo "  kubeadm init --config=kubeadm.yaml"
echo
echo "-------------------------------------------------"
echo
echo "【二】生成工作节点（worker）加入命令"
echo
echo "请在 master1 上执行："
echo
echo "  kubeadm token create --print-join-command"
echo
echo
echo "该命令输出的 join 命令仅用于 worker 节点。"
echo
echo "-------------------------------------------------"
echo
echo "【三】加入其他控制平面节点（master2、master3 ...）"
echo
echo "在 master1 上执行证书上传："
echo
echo "  kubeadm init phase upload-certs --upload-certs"
echo
echo "该命令会输出一个 certificate-key，请保存。"
echo
echo
echo "然后在 master1 上生成 join 命令："
echo
echo "  kubeadm token create --print-join-command"
echo
echo
echo "在其他 master 节点上，将 join 命令补充为："
echo
echo "  kubeadm join <VIP>:<PORT> --token <TOKEN> \\"
echo "    --discovery-token-ca-cert-hash sha256:<HASH> \\"
echo "    --control-plane \\"
echo "    --certificate-key <CERTIFICATE-KEY>"
echo
echo "================================================="
