# longhorn

该 role 通过离线 Helm Chart 安装 Longhorn，为集群提供分布式块存储和默认 StorageClass。

## 主要工作

- 在首个 master 上创建 `longhorn_work_dir`。
- 复制 `longhorn-1.11.2.tgz`。
- 渲染 `longhorn-values.yaml`。
- 等待 kube-apiserver 可访问。
- 创建 `longhorn-system` namespace，并执行 Helm 安装或升级。

## 关键变量

- `longhorn_namespace`: 安装命名空间，默认 `longhorn-system`。
- `longhorn_chart_archive`: 离线 Chart 包。
- `longhorn_data_path`: 节点数据目录，默认 `/var/lib/longhorn`。
- `longhorn_default_storage_class`: 是否设置为默认 StorageClass。
- `longhorn_service_ui_type`: Longhorn UI Service 类型，默认 `ClusterIP`。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags longhorn
```

## 验证

```bash
kubectl -n longhorn-system get pods
kubectl get storageclass
```
