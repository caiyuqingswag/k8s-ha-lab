#!/bin/bash
set -e

NFS_DIR="/data/jiyan/"

echo "⚠️ 你确定要把【当前服务器】作为 NFS 服务端吗？"
echo "共享目录将会是: $NFS_DIR"
echo ""
read -p "请输入 yes 确认，其它任意输入将取消: " confirm

if [ "$confirm" != "yes" ]; then
  echo "❌ 已取消执行，未做任何修改"
  exit 0
fi

echo "✅ 确认成功，开始部署 NFS 服务端..."

echo "➡️ 创建共享目录..."
mkdir -p "$NFS_DIR"
chmod 777 "$NFS_DIR"

echo "➡️ 配置 /etc/exports..."
if ! grep -qE "^$NFS_DIR\s" /etc/exports 2>/dev/null; then
  echo "$NFS_DIR *(rw,sync,no_root_squash)" >> /etc/exports
fi

echo "➡️ 启动 NFS 服务..."
systemctl enable --now nfs-server

echo "➡️ 重新导出目录..."
exportfs -rv

echo "➡️ 当前导出目录："
exportfs -v

echo ""
echo "✅ NFS 服务端部署完成！"
echo "📂 共享根目录: $NFS_DIR"
