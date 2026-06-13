# minio

生产环境 MinIO StatefulSet 部署清单，用于提供 S3 兼容对象存储。

## 文件说明

- `minio-secret.yaml`: MinIO access key 和 secret key。
- `minio-pv.yaml`: 静态 PV。
- `minio-pvc.yaml`: PVC。
- `minio-headless.yaml`: Headless Service。
- `minio-nodeport.yaml`: 对外访问 Service。
- `minio-statefulSet.yaml`: MinIO StatefulSet。

## 推荐应用顺序

```bash
kubectl diff -f .
kubectl apply -f minio-secret.yaml
kubectl apply -f minio-pv.yaml
kubectl apply -f minio-pvc.yaml
kubectl apply -f minio-headless.yaml
kubectl apply -f minio-statefulSet.yaml
kubectl apply -f minio-nodeport.yaml
```

## 生产检查

- 确认 access key/secret key、bucket 规划和备份策略。
- 确认对象存储数据目录所在磁盘容量。

## 验证

```bash
kubectl get pod,svc,pv,pvc -A | grep minio
```
