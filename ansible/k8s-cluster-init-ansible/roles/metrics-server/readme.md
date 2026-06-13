# metrics-server

该 role 通过离线 Helm Chart 安装 metrics-server，为 `kubectl top`、HPA 等能力提供资源指标。

## 主要工作

- 在首个 master 上创建工作目录。
- 复制 `metrics-server-3.13.0.tgz`。
- 渲染 `metrics-server-values.yaml`。
- 等待 kube-apiserver 可访问。
- 创建命名空间并执行 Helm 安装或升级。

## 关键变量

- `metrics_server_namespace`: 安装命名空间。
- `metrics_server_chart_archive`: 离线 Chart 包。
- `metrics_server_replicas`: 副本数。
- `metrics_server_kubelet_insecure_tls`: 是否跳过 kubelet TLS 校验，私有集群常用。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags metrics
```

## 验证

```bash
kubectl -n kube-system get pods | grep metrics-server
kubectl top nodes
```
