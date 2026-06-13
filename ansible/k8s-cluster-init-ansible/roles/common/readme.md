# common

该 role 完成 Kubernetes 节点的基础系统初始化，为后续安装 containerd、kubeadm 和集群组件做准备。

## 主要工作

- 设置主机名。
- 关闭 cloud-init 对 `/etc/hosts` 的接管，并维护集群 hosts 记录。
- 更新 apt 缓存并安装基础工具包。
- 检查并关闭 swap。
- 配置内核模块、sysctl 参数、时间同步和 journald。
- 执行基础环境检查脚本。

## 关键点

- 该 role 在所有节点执行。
- hosts 记录来自 Ansible inventory。
- sysctl 和 systemd 相关修改会通过 handlers 生效。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags common
```

## 验证

```bash
hostname
swapon --show
sysctl net.bridge.bridge-nf-call-iptables
```
