# middleware

该目录保存中间件部署清单和存储方案说明，主要面向 MySQL、Redis、RabbitMQ、MinIO、InfluxDB、MongoDB 等基础组件。

## 目录说明

```text
middleware/
├── monolithic-architecture/     # 单体/小规模环境中间件清单
└── distributed-architecture/    # 分布式存储方案说明
```

`monolithic-architecture` 下按环境划分：

- `dev`: 开发环境。
- `sit`: 集成测试环境。
- `prod`: 生产环境。

每个环境下按组件划分：

- `mysql`
- `redis`
- `rabbit`
- `minio`
- `influxdb`
- `mongodb`

## 推荐部署顺序

中间件一般按以下顺序应用：

```bash
kubectl apply -f <component>-secret.yaml
kubectl apply -f <component>-config.yaml
kubectl apply -f <component>-pv.yaml
kubectl apply -f <component>-pvc.yaml
kubectl apply -f <component>-headless.yaml
kubectl apply -f <component>-statefulSet.yaml
kubectl apply -f <component>-nodeport.yaml
```

部分组件没有 config 文件时跳过对应步骤。

## 注意事项

- 部署前先确认 namespace、StorageClass、PV 路径和节点亲和性是否符合当前环境。
- Secret 中的账号密码建议按环境替换，不要直接复用示例值。
- `prod` 环境部署前建议确认备份、监控、资源限制和恢复方案。
- 如果已使用 Longhorn 或动态 StorageClass，可以考虑将静态 PV/PVC 改造为动态 PVC。

## 验证

```bash
kubectl get sts,po,svc,pv,pvc -A
kubectl describe pod -n <namespace> <pod>
kubectl logs -n <namespace> <pod> --tail=200
```
