# jumpserver

该 role 通过离线 Helm Chart 安装 JumpServer，用于堡垒机和资产访问管理。

## 主要工作

- 在首个 master 上创建 `jumpserver_work_dir`。
- 复制 JumpServer Chart 包。
- 渲染依赖资源和 `jumpserver-values.yaml`。
- 等待 kube-apiserver 可访问。
- 创建命名空间并安装或升级 JumpServer。

## 关键变量

- `jumpserver_namespace`: 安装命名空间。
- `jumpserver_chart_archive`: 离线 Chart 包。
- `jumpserver_hostname`: 访问域名。
- `jumpserver_ingress_enabled`: 是否启用 Chart 内置 Ingress，通常由外部网关接入时设为 `false`。
- `jumpserver_storage_class`: 持久化存储类。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags jumpserver
```

## 验证

```bash
kubectl -n jumpserver get pods,svc,pvc
```
