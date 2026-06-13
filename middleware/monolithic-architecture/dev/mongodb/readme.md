# mongodb

开发环境 MongoDB 清单目录。实际资源位于当前目录下的 `mongodb/` 子目录。

## 使用方式

```bash
kubectl apply -f middleware/monolithic-architecture/dev/mongodb/mongodb/
```

## 验证

```bash
kubectl get pod,svc,pv,pvc -A | grep mongodb
```
