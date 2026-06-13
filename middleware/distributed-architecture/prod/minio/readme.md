# MinIO HA

该目录提供 4 节点 MinIO 分布式模式，数据卷使用 `local-ssd` 静态 Local PV。

镜像版本固定为 `minio/minio:RELEASE.2025-09-07T16-13-09Z`。

## 部署

先确认以下目录已在对应节点创建：

```text
ssd1:/data/local-pv/prod-distributed/minio-0
ssd2:/data/local-pv/prod-distributed/minio-1
ssd3:/data/local-pv/prod-distributed/minio-2
ssd4:/data/local-pv/prod-distributed/minio-3
```

```bash
kubectl apply -f middleware/distributed-architecture/prod/minio/
```

## 访问

- API Service: `minio.prod-distributed.svc.cluster.local:9000`
- Console Service: `minio-console.prod-distributed.svc.cluster.local:9001`

如需集群外访问，建议通过 Ingress/Gateway 暴露，不建议直接把 Console 长期暴露为 NodePort。

## 验证

```bash
kubectl -n prod-distributed get pod -l app=minio
kubectl -n prod-distributed get pvc -l app=minio
kubectl -n prod-distributed rollout status sts/minio --timeout=10m
```
