# kube-vip

该 role 部署 kube-vip 静态 Pod，为 Kubernetes 控制面提供高可用 API VIP。

## 主要工作

- 根据模板生成 kube-vip manifest。
- 在 kubeadm init 前使用 `/etc/kubernetes/super-admin.conf` 启动首个 master 的 kube-vip。
- kubeadm init 后可通过 `use-admin-conf.yml` 切换为 `/etc/kubernetes/admin.conf`。
- 其他 master join 后也会部署 kube-vip。

## 关键变量

- `kube_vip_address`: Kubernetes API VIP，默认引用 `kubevip_api_ip`。
- `kube_vip_dns_name`: API VIP DNS 名称，默认引用 `kubevip_api_name`。
- `kube_vip_interface`: kube-vip 绑定网卡，留空时自动使用默认网卡。
- `kube_vip_image` / `kube_vip_version`: kube-vip 镜像和版本。
- `kube_vip_restart_kubelet`: 渲染静态 Pod 后是否重启 kubelet，默认 `false`。

## 执行方式

首个 master 初始化阶段会随 `init` tag 执行：

```bash
ansible-playbook -i inventory.ini site.yml --tags init
```

单独部署或修复 kube-vip：

```bash
ansible-playbook -i inventory.ini site.yml --tags kubevip
```

## 验证

```bash
ip addr | grep <kube_vip_address>
kubectl -n kube-system get pods | grep kube-vip
```
