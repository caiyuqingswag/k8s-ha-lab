# dirs

该 role 用于在 NFS 服务器上初始化业务目录结构，并设置目录属主。

## 主要工作

- 按 `dir_envs` 和 `dir_components` 的组合批量创建目录。
- 设置每类组件目录的 owner/group。
- 查找并打印已创建的目录列表。

## 关键变量

- `dir_base`: 目录根路径。
- `dir_envs`: 环境列表，例如 dev、test、prod。
- `dir_components`: 组件目录和所属用户映射。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags dir
```

## 验证

```bash
find /data -maxdepth 3 -type d
```
