#!/bin/bash

PUBKEY="/root/.ssh/id_ed25519.pub"
INVENTORY="hosts.ini"
MAX_RETRY=3

echo "========== 初始化环境 =========="

dnf install -y epel-release
dnf install -y ansible-core sshpass
ansible-galaxy collection install ansible.posix

cat > ansible.cfg <<EOF
[defaults]
host_key_checking = False
inventory = $INVENTORY
timeout = 10
forks = 5
EOF


if [ ! -f "$PUBKEY" ]; then
  echo "[INFO] 生成 SSH key..."
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
  ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519
fi

echo "========== 开始逐台初始化 =========="

# 只读取 IPv4 地址
grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$INVENTORY" | while read -r host; do
  [ -z "$host" ] && continue

  echo
  echo "=============================="
  echo "正在处理 $host"

  success=0

  for ((i=1; i<=MAX_RETRY; i++)); do
    echo "第 $i 次尝试，请输入 $host 的 root 密码"

    ansible "$host" -m ansible.posix.authorized_key \
      -a "user=root state=present key='{{ lookup(\"file\", \"$PUBKEY\") }}'" \
      --ask-pass

    if [ $? -eq 0 ]; then
      echo "验证免密..."
      ansible "$host" -m ping
      success=1
      break
    else
      echo "❌ 密码错误或连接失败"
    fi
  done

  if [ $success -eq 0 ]; then
    echo "🚨 $host 连续 $MAX_RETRY 次失败，已跳过"
  fi

done

echo
echo "========== 全部完成 =========="
