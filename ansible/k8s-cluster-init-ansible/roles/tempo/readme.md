# tempo

该 role 通过离线 Helm Chart 安装 Grafana Tempo，用于存储和查询分布式链路追踪数据。

## 主要工作

- 在首个 master 上创建 `tempo_work_dir`。
- 复制 `tempo-1.24.4.tgz`。
- 渲染 `tempo-values.yaml`。
- 可选渲染 Grafana Tempo datasource。
- 等待 kube-apiserver 可访问。
- 创建 `tracing` namespace，并执行 Helm 安装或升级。

## 关键变量

- `tempo_enabled`: 是否启用 Tempo，默认 `true`。
- `tempo_namespace`: 安装命名空间，默认 `tracing`。
- `tempo_storage_class`: 持久化存储类，默认使用 `global_storage_class`。
- `tempo_retention`: trace 保留时间，默认 `168h`。
- `tempo_otlp_grpc_port` / `tempo_otlp_http_port`: OTLP 接收端口。
- `tempo_create_grafana_datasource`: 是否创建 Grafana datasource。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags tempo
```

## 验证

```bash
kubectl -n tracing get pods,svc,pvc
kubectl -n monitoring get configmap | grep tempo
```
