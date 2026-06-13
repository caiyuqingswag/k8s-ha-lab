# trivy-operator

该 role 通过离线 Helm Chart 安装 Trivy Operator，为集群提供漏洞扫描、配置审计、RBAC 审计、暴露密钥扫描和 SBOM 生成能力。

## 主要工作

- 在首个 master 上创建 `trivy_operator_work_dir`。
- 复制 `trivy-operator-0.32.1.tgz`。
- 渲染 `trivy-operator-values.yaml`。
- 等待 kube-apiserver 可访问。
- 创建安全命名空间并执行 Helm 安装或升级。

## 关键变量

- `trivy_operator_namespace`: 安装命名空间，默认 `security`。
- `trivy_operator_target_namespaces`: 扫描目标命名空间，空表示全局。
- `trivy_operator_exclude_namespaces`: 排除的命名空间。
- `trivy_operator_scan_jobs_concurrent_limit`: 并发扫描任务数。
- `trivy_severity`: 关注的漏洞级别。
- `trivy_ignore_unfixed`: 是否忽略未修复漏洞。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags trivy-operator
```

## 验证

```bash
kubectl -n security get pods
kubectl get vulnerabilityreports,configauditreports -A
```
