# apisix-routes-internal

该 role 用于为内网 APISIX 网关生成并应用平台组件的 `ApisixRoute`，把 Grafana、Argo CD、Prometheus、Alertmanager、Longhorn 等内部 Web 服务暴露到内网域名。

## 主要工作

- 在首个 master 上创建工作目录 `apisix_routes_internal_work_dir`。
- 根据 `apisix_internal_routes` 渲染 `apisix-routes-internal.yaml`。
- 检查 kube-apiserver 是否可访问。
- 校验 `ApisixRoute` CRD 已存在，然后执行 `kubectl apply`。

## 关键变量

- `apisix_routes_internal_work_dir`: 生成清单保存目录，默认 `/etc/kubernetes/apisix-routes-internal`。
- `apisix_internal_ingress_class_name`: 内网 APISIX IngressClass，默认 `apisix-internal`。
- `apisix_internal_routes`: 内网域名到后端 Service 的路由列表。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags apisix-routes-internal
```

## 验证

```bash
kubectl get apisixroute -A
kubectl -n monitoring get svc grafana
```
