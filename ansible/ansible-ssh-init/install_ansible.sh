#!/bin/bash
set -e

INVENTORY="hosts.ini"
MAX_RETRY=3
PUBKEY="$HOME/.ssh/id_ed25519.pub"
PRIVKEY="$HOME/.ssh/id_ed25519"

echo "========== 初始化 Ansible 控制机（Ubuntu） =========="

# 1. 安装 Ansible（控制机）
if ! command -v ansible >/dev/null 2>&1; then
  apt update
  apt install -y software-properties-common
  apt install -y ansible-core sshpass
fi

# 2. 安装必要 collection
ansible-galaxy collection install ansible.posix

# 3. Ansible 配置
cat > ansible.cfg <<EOF
[defaults]
host_key_checking = False
inventory = $INVENTORY
timeout = 10
forks = 5
EOF

# 4. 生成 SSH key（控制机）
if [ ! -f "$PUBKEY" ]; then
  echo "[INFO] 生成 SSH key..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -N "" -f "$PRIVKEY"
fi

echo "========== 开始逐台分发 SSH Key =========="

grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$INVENTORY" | while read -r host; do
  [ -z "$host" ] && continue

  echo
  echo "=============================="
  echo "正在处理 $host"

  success=0

  for ((i=1; i<=MAX_RETRY; i++)); do
    echo "第 $i 次尝试，请输入 $host 的 ubuntu 用户密码"

    ansible "$host" \
      -m ansible.posix.authorized_key \
      -a "user=ubuntu state=present key='{{ lookup(\"file\", \"$PUBKEY\") }}'" \
      --ask-pass \
      --become \
      --ask-become-pass

    if [ $? -eq 0 ]; then
      echo "验证免密..."
      ansible "$host" -m ping -e ansible_become=false
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
