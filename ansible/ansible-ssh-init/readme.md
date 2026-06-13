# ansible-ssh-init

该目录用于初始化 Ansible 控制机到目标节点的 SSH 访问能力，适合在正式执行 `k8s-cluster-init-ansible` 前先完成免密登录、Ansible 安装和基础连通性检查。

## 文件说明

- `hosts.ini`: 初始化 SSH 使用的目标主机列表。
- `install_ansible.sh`: 控制机初始化脚本，会安装 Ansible/sshpass、生成 SSH key、生成本目录 `ansible.cfg`，并按 inventory 主机列表分发公钥。

## 使用方式

进入目录：

```bash
cd ansible/ansible-ssh-init
```

确认 `hosts.ini` 中的节点 IP 和用户配置正确，然后执行：

```bash
bash install_ansible.sh
```

如需指定 inventory 或 SSH 用户：

```bash
INVENTORY=hosts.ini SSH_USER=ubuntu bash install_ansible.sh
```

## 验证

```bash
ansible -i hosts.ini all -m ping
ssh ubuntu@192.168.0.51 hostname
```

## 注意事项

- 脚本要求普通用户执行，不要使用 root 或 sudo 直接运行。
- 首次分发公钥时需要目标节点密码或已存在的可登录凭据。
- 该目录只负责控制机和 SSH 初始化，真正的 Kubernetes 部署在 `ansible/k8s-cluster-init-ansible` 中执行。
