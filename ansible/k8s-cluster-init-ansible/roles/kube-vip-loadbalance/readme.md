# kube-vip-loadbalance

该 role 用于部署 kube-vip cloud provider 和 Service LoadBalancer DaemonSet，使 Kubernetes `Service type=LoadBalancer` 可以从指定地址池分配 VIP。

当前 `site.yml` 中该 play 默认注释，建议确认地址池、网卡和网络策略后再启用。

## 主要工作

- 在首个 master 上创建 `kubevip_lb_work_dir`。
- 渲染 kube-vip cloud controller ConfigMap。
- 渲染 kube-vip cloud provider Deployment/RBAC 清单。
- 复制 kube-vip LoadBalancer RBAC 清单。
- 渲染 kube-vip LoadBalancer DaemonSet。
- 使用显式 kubeconfig 执行 `kubectl apply`。
- 等待 `kube-vip-cloud-provider` Deployment 和 `kube-vip-ds` DaemonSet ready。

## 关键变量

- `kubevip_namespace`: 安装命名空间，默认 `kube-system`。
- `kubevip_lb_work_dir`: 渲染后的清单目录，默认 `/etc/kubernetes/kube-vip-loadbalance`。
- `kubevip_kubeconfig`: kubectl 使用的 kubeconfig，默认 `/etc/kubernetes/admin.conf`。
- `kubevip_lb_range`: LoadBalancer 可分配地址池，例如 `172.16.15.70-172.16.15.75`。
- `kubevip_interface`: VIP 绑定网卡，例如 `eth0`。
- `kubevip_image`: kube-vip DaemonSet 镜像。
- `kubevip_cloud_provider_image`: kube-vip cloud provider 镜像。

## 执行方式

启用 `site.yml` 中的 `kubevip-lb` play 后执行：

```bash
ansible-playbook -i inventory.ini site.yml --tags kubevip-lb
```

## 验证

```bash
kubectl -n kube-system get deploy kube-vip-cloud-provider
kubectl -n kube-system get ds kube-vip-ds
kubectl get svc -A --field-selector spec.type=LoadBalancer
```

创建测试 Service 后，可以确认 `EXTERNAL-IP` 是否从 `kubevip_lb_range` 中分配。
