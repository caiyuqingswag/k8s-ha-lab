#!/bin/bash
set -e

FILE="helm-v4.0.4-linux-amd64.tar.gz"

if [ ! -f "$FILE" ]; then
  echo "❌ 找不到文件: $FILE"
  exit 1
fi

echo "➡️ 解压 Helm..."
tar -zxvf $FILE

echo "➡️ 安装 Helm 到 /usr/local/bin..."
sudo mv linux-amd64/helm /usr/local/bin/helm

echo "➡️ 设置可执行权限..."
sudo chmod +x /usr/local/bin/helm

echo "➡️ 验证安装..."
helm version

echo "✅ Helm 安装完成！"


