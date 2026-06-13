# kube-prometheus-stack

该 role 通过离线 Helm Chart 安装 kube-prometheus-stack，提供 Prometheus、Alertmanager、Grafana Dashboard 和 ServiceMonitor 体系。

## 主要工作

- 在首个 master 上创建工作目录。
- 复制 `kube-prometheus-stack-85.0.3.tgz`。
- 渲染 `kube-prometheus-stack-values.yaml`。
- 可选渲染 Grafana Prometheus datasource。
- 等待 kube-apiserver 可访问。
- 创建 `monitoring` namespace 并执行 Helm 安装或升级。

## 关键变量

- `kube_prometheus_stack_namespace`: 安装命名空间，通常为 `monitoring`。
- `kube_prometheus_stack_chart_archive`: 离线 Chart 包。
- `global_storage_class`: Prometheus、Alertmanager 等组件使用的默认存储类。
- `kube_prometheus_stack_helm_timeout`: Helm 等待超时时间。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags prometheus
```

## 验证

```bash
kubectl -n monitoring get pods,svc,pvc
kubectl get servicemonitor -A
```
