# paas

该目录保存 PaaS 平台相关服务的 Kubernetes/Argo CD 部署清单，适合由 Argo CD 统一托管，也可以用 `kubectl apply` 手动应用。

## 清单范围

主要包含：

- `apihub-server.yaml`
- `data-server.yaml`
- `gateway.yaml`
- `gw-admin.yaml`
- `manage.yaml`
- `msg-server.yaml`
- `openapi-server.yaml`
- `paas-admin.yaml`
- `paas-components.yaml`
- `paas-port.yaml`
- `platform.yaml`
- `print-server.yaml`
- `print-web.yaml`
- `tornaitex.yaml`
- `tornaitex-web.yaml`
- `user.yaml`

## 使用方式

手动应用单个服务：

```bash
kubectl apply -f argo_cd_deployment/paas/gateway.yaml
```

批量应用：

```bash
kubectl apply -f argo_cd_deployment/paas/
```

## 部署前检查

- 确认目标 namespace 已创建。
- 确认镜像仓库地址、镜像 tag 和 imagePullSecret 可用。
- 确认 ConfigMap、Secret、PVC、Service 依赖已经准备好。
- 如果服务通过 APISIX 或 Istio 暴露，需要同步检查对应路由清单。

## 验证

```bash
kubectl get deploy,po,svc -A | grep -E "paas|gateway|platform"
kubectl describe pod -n <namespace> <pod>
kubectl logs -n <namespace> <pod> --tail=200
```
