#!/bin/bash
set -e

# 禁止 root / sudo 执行
if [ "$EUID" -eq 0 ]; then
  echo "❌ 请不要用 sudo 或 root 运行此脚本"
  exit 1
fi

INVENTORY="hosts.ini"
MAX_RETRY=3
PUBKEY="$HOME/.ssh/id_ed25519.pub"
PRIVKEY="$HOME/.ssh/id_ed25519"

echo "========== 初始化 Ansible 控制机（Ubuntu） =========="

# 1. 安装 Ansible（控制机）
if ! command -v ansible >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y software-properties-common ansible-core sshpass
fi

# 2. 安装必要 collection
ansible-galaxy collection install ansible.posix

# 3. Ansible 配置（当前目录）
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

echo "========== 开始逐台初始化（SSH + sudo） =========="

grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$INVENTORY" | while read -r host; do
  [ -z "$host" ] && continue

  echo
  echo "=============================="
  echo "正在处理 $host"

  for ((i=1; i<=MAX_RETRY; i++)); do
    echo "第 $i 次尝试，请输入 $host 的 ubuntu 用户密码"

    # 1️⃣ 分发 SSH key
    ansible "$host" \
      -m ansible.posix.authorized_key \
      -a "user=ubuntu state=present key='{{ lookup(\"file\", \"$PUBKEY\") }}'" \
      --ask-pass \
      --become \
      --ask-become-pass || continue

    # 2️⃣ 配置 sudo NOPASSWD
    echo "配置 sudo NOPASSWD（ubuntu 用户）..."
    ansible "$host" \
      -m ansible.builtin.copy \
      -a "dest=/etc/sudoers.d/90-ansible-ubuntu content='ubuntu ALL=(ALL) NOPASSWD:ALL\n' owner=root group=root mode=0440" \
      --ask-pass \
      --become \
      --ask-become-pass || continue

    # 3️⃣ 验证 SSH + sudo
    echo "验证 SSH + sudo..."
    ansible "$host" -m command -a "sudo -n true"

    echo "✅ $host 初始化完成"
    break
  done
done

echo
echo "========== 全部完成（SSH + sudo 已统一） =========="
