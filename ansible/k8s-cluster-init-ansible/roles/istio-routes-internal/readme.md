# istio-routes-internal

该 role 用于生成并应用 Istio 内网入口路由，把平台 Web 控制台通过 `istio-ingress-internal` 暴露给内网或白名单 CLB。

## 主要工作

- 在首个 master 上创建工作目录。
- 根据变量渲染 `Gateway` 和 `VirtualService` 清单。
- 等待 kube-apiserver 可访问。
- 使用 `kubectl apply` 应用内网路由。

## 关键变量

- `istio_routes_internal_work_dir`: 清单生成目录。
- `istio_internal_gateway_namespace`: 内网网关命名空间。
- `istio_internal_gateway_name`: 内网 Gateway 名称。
- `istio_internal_routes`: 内网域名到 Service 的路由列表。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags istio-routes-internal
```

## 验证

```bash
kubectl get gateway,virtualservice -A
kubectl -n istio-ingress-internal get svc,pods
```
