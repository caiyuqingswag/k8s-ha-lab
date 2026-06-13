# loki

该 role 通过离线 Helm Chart 安装 Grafana Loki，用于集中存储和查询集群日志。

## 主要工作

- 在首个 master 上创建 `loki_work_dir`。
- 复制 `loki-14.0.0.tgz`。
- 渲染 `loki-values.yaml`。
- 可选渲染 Grafana Loki datasource。
- 等待 kube-apiserver 可访问。
- 创建日志命名空间并执行 Helm 安装或升级。

## 关键变量

- `loki_namespace`: 安装命名空间，默认通常为 `logging`。
- `loki_chart_archive`: 离线 Chart 包。
- `loki_storage_class`: 持久化存储类。
- `loki_storage_size`: Loki 数据盘容量，默认 `50Gi`。
- `loki_create_grafana_datasource`: 是否创建 Grafana datasource。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags loki
```

## 验证

```bash
kubectl -n logging get pods,svc,pvc
kubectl -n monitoring get configmap | grep loki
```
