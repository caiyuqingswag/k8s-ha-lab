# verdaccio

该 role 通过离线 Helm Chart 安装 Verdaccio，用于在集群内提供私有 npm registry。

## 主要工作

- 在首个 master 上创建 `verdaccio_work_dir`。
- 复制 `verdaccio-4.31.0.tgz`。
- 渲染 `verdaccio-values.yaml`。
- 等待 kube-apiserver 可访问。
- 创建 `npm-registry` namespace，并执行 Helm 安装或升级。

## 关键变量

- `verdaccio_enabled`: 是否启用 Verdaccio，默认 `true`。
- `verdaccio_namespace`: 安装命名空间，默认 `npm-registry`。
- `verdaccio_hostname`: 访问域名，默认 `npm.itexcloud.com`。
- `verdaccio_service_type`: Service 类型，默认 `ClusterIP`。
- `verdaccio_persistence_enabled`: 是否启用持久化。
- `verdaccio_uplink_registry`: 上游 npm registry。
- `verdaccio_users`: 初始用户配置，建议使用 Ansible Vault 管理密码。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags verdaccio
```

## 验证

```bash
kubectl -n npm-registry get pods,svc,pvc
npm ping --registry http://<verdaccio-service>:4873
```
