# argocd

该 role 通过离线 Helm Chart 安装 Argo CD，用于 Kubernetes 集群内的 GitOps 持续交付。

## 主要工作

- 在首个 master 上创建 `argocd_work_dir`。
- 复制 `argo-cd-9.5.14.tgz` 到目标节点。
- 渲染 `argocd-values.yaml`。
- 等待 kube-apiserver 可访问。
- 创建 `argocd` namespace，并执行 `helm upgrade --install`。

## 关键变量

- `argocd_namespace`: 安装命名空间，默认 `argocd`。
- `argocd_chart_archive`: 离线 Chart 包，默认 `argo-cd-9.5.14.tgz`。
- `argocd_server_service_type`: Server Service 类型，默认 `ClusterIP`。
- `argocd_server_insecure`: 是否让 Argo CD Server 以非 TLS 模式运行，默认 `true`，适合由外部网关终止 TLS。
- `argocd_ha_enabled`: 是否启用 HA 副本，默认 `false`。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags argocd
```

## 验证

```bash
kubectl -n argocd get pods,svc
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```
