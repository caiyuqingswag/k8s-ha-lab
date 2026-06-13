# kyverno

该 role 通过离线 Helm Chart 安装 Kyverno 策略引擎，用于 Kubernetes 准入控制、配置审计和安全基线策略。

## 主要工作

- 在首个 master 上创建工作目录。
- 复制 `kyverno-3.8.0.tgz`。
- 渲染 `kyverno-values.yaml`。
- 等待 kube-apiserver 可访问。
- 创建命名空间并执行 Helm 安装或升级。

## 关键变量

- `kyverno_namespace`: 安装命名空间。
- `kyverno_chart_archive`: 离线 Chart 包。
- `kyverno_admission_controller_replicas`: admission controller 副本数。
- `kyverno_background_controller_replicas`: background controller 副本数。
- `kyverno_cleanup_controller_replicas`: cleanup controller 副本数。
- `kyverno_reports_controller_replicas`: reports controller 副本数。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags kyverno
```

## 验证

```bash
kubectl -n kyverno get pods
kubectl get validatingadmissionpolicy,clusterpolicy
```
