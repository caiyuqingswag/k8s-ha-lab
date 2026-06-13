# group_vars

该目录保存 `k8s-cluster-init-ansible` 的全局变量和敏感变量，是部署前最需要检查的配置入口之一。

## 文件说明

- `all.yml`: 普通全局变量，例如 Kubernetes 版本、镜像仓库、Pod/Service 网段、控制面 endpoint、默认 StorageClass、Velero S3 参数等。
- `vault.yml`: 敏感变量文件，建议使用 Ansible Vault 加密保存。

## 部署前重点检查

`all.yml` 中建议至少确认：

- `k8s_version`: Kubernetes 版本。
- `image_repo`: kubeadm 控制面镜像仓库。
- `pod_cidr`: Pod 网段。
- `service_cidr`: Service 网段。
- `control_plane_endpoint`: kubeadm 控制面入口，通常是 kube-vip DNS 加 6443。
- `global_storage_class`: 平台组件默认 StorageClass。
- `velero_*`: Velero 对接 S3/MinIO 的参数。

`vault.yml` 中建议保存：

- 平台组件初始密码。
- 数据库、中间件账号密码。
- S3/MinIO access key 和 secret key。
- 其他不适合明文提交的 token 或证书内容。

## Ansible Vault 示例

创建加密文件：

```bash
ansible-vault create group_vars/vault.yml
```

编辑加密文件：

```bash
ansible-vault edit group_vars/vault.yml
```

执行 playbook 时输入 vault 密码：

```bash
ansible-playbook -i inventory.ini site.yml --ask-vault-pass
```

使用密码文件：

```bash
ansible-playbook -i inventory.ini site.yml --vault-password-file .vault-pass
```

## 注意事项

- 生产环境不要把真实密码、token、access key 明文提交到 Git。
- 修改 `pod_cidr`、`service_cidr`、`control_plane_endpoint` 这类集群级变量前，要确认是否已经初始化过集群；已初始化集群不建议随意变更。
- 修改 `global_storage_class` 会影响后续安装组件的 PVC 选择。
