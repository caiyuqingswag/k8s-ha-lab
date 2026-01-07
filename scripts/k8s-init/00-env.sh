#!/bin/bash
set -e

########################################
# 全局变量
########################################
export K8S_VERSION="1.34.2"
export IMAGE_REPO="registry.cn-hangzhou.aliyuncs.com/google_containers"
export PAUSE_IMAGE="registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.9"

########################################
# OS 检查
########################################
echo "==> Check OS"
cat /etc/os-release
echo "Kernel: $(uname -r)"

if ! grep -qi "rocky linux 9" /etc/os-release; then
  echo "ERROR: This script is only for Rocky Linux 9"
  exit 1
fi
