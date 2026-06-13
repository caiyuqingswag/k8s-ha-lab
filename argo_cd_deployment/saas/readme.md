# saas

该目录保存 SaaS/业务系统相关服务的 Kubernetes/Argo CD 部署清单，包括多个 `klinx-*` 服务、网关、配置和 heapdump 持久化资源。

## 清单范围

主要类型包括：

- 业务服务 Deployment/Service 清单，例如 `klinx-base-server.yaml`、`klinx-gateway-server.yaml`。
- 网关和开放接口服务，例如 `klinx-apigateway-server.yaml`、`klinx-openapi-server.yaml`。
- 配置清单，例如 `saas-configmap.yml`。
- heapdump 相关 PV/PVC，例如 `heapdump-pv.yaml`、`heapdump-pvc.yaml`。
- CKS 相关说明文档 `readme-cks.md`。

## 使用方式

手动应用配置和存储：

```bash
kubectl apply -f argo_cd_deployment/saas/saas-configmap.yml
kubectl apply -f argo_cd_deployment/saas/heapdump-pv.yaml
kubectl apply -f argo_cd_deployment/saas/heapdump-pvc.yaml
```

应用单个服务：

```bash
kubectl apply -f argo_cd_deployment/saas/klinx-gateway-server.yaml
```

批量应用：

```bash
kubectl apply -f argo_cd_deployment/saas/
```

## 部署前检查

- 确认 namespace、ConfigMap、Secret、PVC 和镜像拉取凭据已准备。
- 确认服务使用的数据库、Redis、MQ、MinIO 等中间件地址可访问。
- 确认域名入口、APISIXRoute 或 Istio VirtualService 已按环境规划。

## 验证

```bash
kubectl get deploy,po,svc -A | grep klinx
kubectl get cm,secret,pvc -A | grep -E "saas|heapdump|klinx"
kubectl logs -n <namespace> <pod> --tail=200
```
