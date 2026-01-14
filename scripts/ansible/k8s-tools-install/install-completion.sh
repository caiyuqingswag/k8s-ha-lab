#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "❌ 请用 sudo 执行"
  exit 1
fi

echo "➡️ 安装 bash-completion..."
dnf install -y bash-completion || apt-get install -y bash-completion

echo "➡️ 配置 kubectl completion..."
kubectl completion bash >/etc/bash_completion.d/kubectl || true

echo "➡️ 配置 helm completion..."
helm completion bash >/etc/bash_completion.d/helm || true

echo "✅ Completion 安装完成"
echo "⚠️ 请重新登录 shell 或执行: source /etc/profile"
