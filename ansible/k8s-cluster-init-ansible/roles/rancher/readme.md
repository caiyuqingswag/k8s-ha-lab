# rancher

该 role 通过离线 Helm Chart 安装 Rancher，用于 Kubernetes 多集群管理和图形化运维。

## 主要工作

- 在首个 master 上创建 `rancher_work_dir`。
- 复制 `rancher-2.14.1.tgz`。
- 渲染 `rancher-values.yaml`。
- 等待 kube-apiserver 可访问。
- 创建 `cattle-system` namespace，并执行 Helm 安装或升级。

## 关键变量

- `rancher_namespace`: 安装命名空间，默认 `cattle-system`。
- `rancher_hostname`: 访问域名，默认 `rancher.itexcloud.com`。
- `rancher_bootstrap_password`: 初始密码，建议通过 Ansible Vault 管理。
- `rancher_ingress_enabled`: 是否启用 Chart 内置 Ingress，默认 `false`。
- `rancher_tls_source`: TLS 来源，默认 `external`。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags rancher
```

## 验证

```bash
kubectl -n cattle-system get pods,svc
```
