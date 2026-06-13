# longhorn-prereq

该 role 在所有节点安装 Longhorn 运行前置依赖，确保节点具备挂载、iSCSI/NFS 等存储能力。

## 主要工作

- 安装 Longhorn 所需系统包。
- 启用并启动相关服务。
- 确保 Longhorn 数据目录存在。
- 为后续 `longhorn` role 安装存储系统做准备。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags longhorn-prereq
```

## 验证

```bash
systemctl status iscsid
lsblk
```
