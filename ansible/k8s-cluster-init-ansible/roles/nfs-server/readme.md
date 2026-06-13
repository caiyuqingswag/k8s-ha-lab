# nfs-server

该 role 在 `nfs-server` 主机组上安装并配置 NFS 服务，为集群或业务提供共享目录。

## 主要工作

- 安装 `nfs-kernel-server`。
- 创建共享目录。
- 维护 `/etc/exports` 中的 Kubernetes NFS 导出配置。
- reload exports。
- 启动并启用 NFS 服务。
- 打印当前 NFS exports。

## 关键变量

- `nfs_dir`: 共享目录，默认 `/data/jiyan`。
- `nfs_export_opts`: 导出参数，默认 `rw,sync,no_subtree_check,no_root_squash`。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags nfs
```

## 验证

```bash
exportfs -v
systemctl status nfs-kernel-server
```
