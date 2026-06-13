# istio-routes-public

该 role 用于生成并应用 Istio 公网业务入口路由，把业务域名通过 `istio-ingress-public` 暴露出去。

## 主要工作

- 在首个 master 上创建工作目录。
- 渲染公网 `Gateway` 和业务 `VirtualService`。
- 等待 kube-apiserver 可访问。
- 应用生成的清单。

## 关键变量

- `istio_routes_public_work_dir`: 清单生成目录。
- `istio_public_gateway_namespace`: 公网网关命名空间。
- `istio_public_gateway_name`: 公网 Gateway 名称。
- `istio_public_routes`: 公网域名到后端 Service 的路由列表。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags istio-routes-public
```

## 验证

```bash
kubectl get gateway,virtualservice -A
kubectl -n istio-ingress-public get svc,pods
```
