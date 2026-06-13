# cni

该 role 在首个 master 上通过离线 Helm Chart 安装 Cilium CNI，用于 Kubernetes Pod 网络、kube-proxy replacement、NodePort 和 Hubble 可观测能力。

## 主要工作

- 限制只在首个 master 执行。
- 等待 kube-apiserver 可访问。
- 创建 `cilium_work_dir`。
- 复制 `cilium-1.19.4.tgz`。
- 渲染 `cilium-values.yaml`。
- 执行 `helm upgrade --install` 安装 Cilium。

## 关键变量

- `cilium_version`: Cilium 版本，默认 `1.19.4`。
- `k8s_service_host`: Kubernetes API 地址，默认使用 `kubevip_api_ip`。
- `cilium_kubeproxy_replacement`: 是否启用 kube-proxy replacement，默认 `true`。
- `cilium_routing_mode`: 路由模式，默认 `tunnel`。
- `cilium_tunnel_protocol`: 隧道协议，默认 `vxlan`。
- `cilium_hubble_enabled`: 是否启用 Hubble，默认 `true`。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags cilium
```

## 验证

```bash
kubectl -n kube-system get pods -l k8s-app=cilium
cilium status
```
