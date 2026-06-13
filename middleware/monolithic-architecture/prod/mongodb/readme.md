# mongodb

生产环境 MongoDB 清单目录。实际资源位于当前目录下的 `mongodb/` 子目录。

## 使用方式

```bash
kubectl diff -f middleware/monolithic-architecture/prod/mongodb/mongodb/
kubectl apply -f middleware/monolithic-architecture/prod/mongodb/mongodb/
```

## 生产检查

- 确认用户密码、PV 路径、备份和恢复方案。
- 确认业务连接地址、端口和访问控制。

## 验证

```bash
kubectl get pod,svc,pv,pvc -A | grep mongodb
```
