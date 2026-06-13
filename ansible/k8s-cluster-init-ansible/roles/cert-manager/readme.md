# cert-manager

该 role 通过离线 Helm Chart 安装 cert-manager，为集群提供证书签发、续期和 Webhook 能力。

## 主要工作

- 在首个 master 上创建 `cert_manager_work_dir`。
- 复制 `cert-manager-v1.20.2.tgz`。
- 渲染 `cert-manager-values.yaml`。
- 等待 kube-apiserver 可访问。
- 创建 `cert-manager` namespace，并使用 Helm 安装或升级。

## 关键变量

- `cert_manager_version`: cert-manager 版本，默认 `v1.20.2`。
- `cert_manager_namespace`: 安装命名空间，默认 `cert-manager`。
- `cert_manager_install_crds`: 是否安装 CRD，默认 `true`。
- `cert_manager_replica_count`: 控制器副本数，默认 `1`。
- `cert_manager_prometheus_enabled`: 是否暴露 Prometheus 指标，默认 `true`。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags cert
```

## 验证

```bash
kubectl -n cert-manager get pods
kubectl get crd | grep cert-manager
```
