# redis

生产环境 Redis StatefulSet 部署清单。

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
kubectl diff -f .
kubectl apply -f redis-secret.yaml
kubectl apply -f redis-config.yaml
kubectl apply -f redis-pv.yaml
kubectl apply -f redis-pvc.yaml
kubectl apply -f redis-headless.yaml
kubectl apply -f redis-statefulSet.yaml
kubectl apply -f redis-nodeport.yaml
```

## 生产检查

- 确认密码、持久化策略和 AOF/RDB 配置。
- 确认访问白名单和端口暴露方式。

## 验证

```bash
kubectl get pod,svc,pv,pvc -A | grep redis
```
