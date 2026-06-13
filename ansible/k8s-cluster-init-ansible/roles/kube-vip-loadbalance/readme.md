# kube-vip-loadbalance

该 role 用于部署 kube-vip cloud provider 和 LoadBalancer 组件，使 Kubernetes `Service type=LoadBalancer` 可以从指定地址池分配 VIP。

## 主要工作

- 渲染 kube-vip cloud controller 的 ConfigMap。
- 渲染 kube-vip LoadBalancer DaemonSet。
- 应用 RBAC、cloud controller 和 LoadBalancer 相关清单。

## 关键变量

- `kubevip_lb_range`: LoadBalancer 可分配的地址段。
- `kubevip_interface`: VIP 绑定网卡。
- `kubevip_image`: kube-vip LoadBalancer DaemonSet 镜像。
- `kubevip_cloud_provider_image`: kube-vip cloud provider 镜像。
- 该 role 会把临时清单渲染到 `/tmp/kube-vip-cloud-controller-configmap.yaml` 和 `/tmp/kube-vip-lb.yaml`。

## 执行方式

当前 `site.yml` 中该 play 默认注释，启用后可执行：

```bash
ansible-playbook -i inventory.ini site.yml --tags kubevip-lb
```

## 验证

```bash
kubectl -n kube-system get pods | grep kube-vip
kubectl get svc -A --field-selector spec.type=LoadBalancer
```
