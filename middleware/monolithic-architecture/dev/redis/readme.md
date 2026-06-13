# redis

开发环境 Redis StatefulSet 部署清单。

## 文件说明

- `redis-secret.yaml`: Redis 密码等敏感配置。
- `redis-config.yaml`: Redis 配置。
- `redis-pv.yaml`: 静态 PV。
- `redis-pvc.yaml`: PVC。
- `redis-headless.yaml`: Headless Service。
- `redis-nodeport.yaml`: 对外访问 Service。
- `redis-statefulSet.yaml`: Redis StatefulSet。

## 推荐应用顺序

```bash
kubectl apply -f redis-secret.yaml
kubectl apply -f redis-config.yaml
kubectl apply -f redis-pv.yaml
kubectl apply -f redis-pvc.yaml
kubectl apply -f redis-headless.yaml
kubectl apply -f redis-statefulSet.yaml
kubectl apply -f redis-nodeport.yaml
```

## 验证

```bash
kubectl get pod,svc,pv,pvc -A | grep redis
```
