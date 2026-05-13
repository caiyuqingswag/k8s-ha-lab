#!/usr/bin/env bash
set -Eeuo pipefail

# 禁止 root / sudo 执行
if [ "${EUID}" -eq 0 ]; then
  echo "❌ 请不要用 sudo 或 root 运行此脚本"
  exit 1
fi

INVENTORY="${INVENTORY:-hosts.ini}"
SSH_USER="${SSH_USER:-ubuntu}"
MAX_RETRY="${MAX_RETRY:-3}"

PUBKEY="${HOME}/.ssh/id_ed25519.pub"
PRIVKEY="${HOME}/.ssh/id_ed25519"

ANSIBLE_CFG_FILE="ansible.cfg"

echo "========== 初始化 Ansible 控制机 =========="
echo "Inventory: ${INVENTORY}"
echo "SSH user:  ${SSH_USER}"

if [ ! -f "${INVENTORY}" ]; then
  echo "❌ 找不到 inventory 文件: ${INVENTORY}"
  exit 1
fi

# 1. 安装 Ansible 和 sshpass
if ! command -v ansible >/dev/null 2>&1; then
  echo "[INFO] 安装 ansible-core / sshpass ..."
  sudo apt update
  sudo apt install -y ansible-core sshpass
else
  echo "[OK] ansible 已安装: $(ansible --version | head -n1)"
fi

# 2. 安装必要 collection
echo "[INFO] 安装 Ansible collection: ansible.posix ..."
ansible-galaxy collection install ansible.posix

# 3. 生成 SSH key
if [ ! -f "${PUBKEY}" ]; then
  echo "[INFO] 生成 SSH key: ${PRIVKEY}"
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
  ssh-keygen -t ed25519 -N "" -f "${PRIVKEY}" -C "${USER}@ansible-control"
else
  echo "[OK] SSH public key 已存在: ${PUBKEY}"
fi

chmod 700 "${HOME}/.ssh"
chmod 600 "${PRIVKEY}"
chmod 644 "${PUBKEY}"

# 4. 生成当前目录 ansible.cfg
# 使用 StrictHostKeyChecking=accept-new，比 host_key_checking=False 更安全
cat > "${ANSIBLE_CFG_FILE}" <<EOF
[defaults]
inventory = ${INVENTORY}
host_key_checking = True
timeout = 15
forks = 10
retry_files_enabled = False
interpreter_python = auto_silent
stdout_callback = default

[ssh_connection]
ssh_args = -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=~/.ssh/known_hosts -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
EOF

echo "[OK] 已生成 ${ANSIBLE_CFG_FILE}"

# 5. 从 inventory 提取目标主机
# 支持：
#   192.168.0.51
#   master1 ansible_host=192.168.0.51
# 排除分组、变量、注释、空行
mapfile -t HOSTS < <(
  awk '
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*#/ { next }
    /^\[/ { next }
    /ansible_host=/ {
      for (i=1; i<=NF; i++) {
        if ($i ~ /^ansible_host=/) {
          sub(/^ansible_host=/, "", $i)
          print $i
        }
      }
      next
    }
    {
      print $1
    }
  ' "${INVENTORY}" | sort -u
)

if [ "${#HOSTS[@]}" -eq 0 ]; then
  echo "❌ 没有从 ${INVENTORY} 解析到任何主机"
  exit 1
fi

echo
echo "将初始化以下主机："
printf '  - %s\n' "${HOSTS[@]}"
echo

# 6. 临时 inventory 目录
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "========== 开始逐台初始化 SSH key + sudo NOPASSWD =========="

for host in "${HOSTS[@]}"; do
  echo
  echo "=============================="
  echo "正在处理 ${host}"

  TMP_INV="${TMP_DIR}/${host}.ini"

  cat > "${TMP_INV}" <<EOF
[bootstrap]
${host} ansible_user=${SSH_USER} ansible_become=true ansible_become_method=sudo
EOF

  success=false

  for ((i=1; i<=MAX_RETRY; i++)); do
    echo
    echo "第 ${i}/${MAX_RETRY} 次尝试：${host}"
    echo "请输入 ${host} 的 ${SSH_USER} 用户 SSH 密码和 sudo 密码"

    # 6.1 分发 SSH public key
    echo "[1/4] 分发 SSH key ..."
    if ! ansible bootstrap \
      -i "${TMP_INV}" \
      -m ansible.posix.authorized_key \
      -a "user=${SSH_USER} state=present key={{ lookup('file', '${PUBKEY}') }}" \
      --ask-pass \
      --become \
      --ask-become-pass; then
      echo "⚠️  SSH key 分发失败，准备重试"
      continue
    fi

    # 6.2 配置 sudo NOPASSWD，并用 visudo 校验
    echo "[2/4] 配置 sudo NOPASSWD ..."
    if ! ansible bootstrap \
      -i "${TMP_INV}" \
      -m ansible.builtin.copy \
      -a "dest=/etc/sudoers.d/90-ansible-${SSH_USER} content='${SSH_USER} ALL=(ALL) NOPASSWD:ALL\n' owner=root group=root mode=0440 validate='/usr/sbin/visudo -cf %s'" \
      --become; then
      echo "⚠️  sudoers 配置失败，准备重试"
      continue
    fi

    # 6.3 验证免密 SSH
    echo "[3/4] 验证免密 SSH ..."
    if ! ansible bootstrap \
      -i "${TMP_INV}" \
      -m ansible.builtin.ping; then
      echo "⚠️  免密 SSH 验证失败，准备重试"
      continue
    fi

    # 6.4 验证免密 sudo
    echo "[4/4] 验证免密 sudo ..."
    if ! ansible bootstrap \
      -i "${TMP_INV}" \
      -m ansible.builtin.command \
      -a "whoami" \
      --become \
      -o | grep -q "root"; then
      echo "⚠️  免密 sudo 验证失败，准备重试"
      continue
    fi

    echo "✅ ${host} 初始化完成"
    success=true
    break
  done

  if [ "${success}" != "true" ]; then
    echo "❌ ${host} 初始化失败，已达到最大重试次数"
    exit 1
  fi
done

echo
echo "========== 全部完成 =========="
echo "SSH key 已分发"
echo "sudo NOPASSWD 已配置"
echo "ansible.cfg 已生成"
echo
echo "你现在可以测试："
echo "  ansible all -m ping"
echo "  ansible all -m command -a 'whoami' --become"