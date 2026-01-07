#!/bin/bash
set -e

chmod +x ./*.sh

./00-env.sh
./01-os-init.sh
./02-containerd.sh
./03-kubernetes.sh

echo "================================================="
echo " Rocky Linux 9 Kubernetes 节点初始化完成"
echo "================================================="
