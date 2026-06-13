# local-path

该 role 安装 local-path-provisioner，为集群提供基于节点本地目录的简易动态存储类。

## 主要工作

- 在首个 master 上创建工作目录。
- 渲染 `local-path.yaml`。
- 等待 kube-apiserver 可访问。
- 应用 local-path-provisioner 清单。

## 关键变量

- `local_path_namespace`: 安装命名空间，通常为 `local-path-storage`。
- `local_path_storage_class`: StorageClass 名称。
- `local_path_node_path`: 节点本地数据目录，默认 `/data/local-path-provisioner`。
- `local_path_default_class`: 是否设置为默认 StorageClass。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags local-path
```

## 验证

```bash
kubectl get storageclass
kubectl -n local-path-storage get pods
```
