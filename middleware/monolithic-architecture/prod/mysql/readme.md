# mysql

生产环境 MySQL StatefulSet 部署清单。

## 文件说明

- `mysql-secret.yaml`: MySQL 账号密码等敏感配置。
- `mysql-config.yaml`: MySQL 配置。
- `mysql-pv.yaml`: 静态 PV。
- `mysql-pvc.yaml`: PVC。
- `mysql-headless.yaml`: StatefulSet 使用的 Headless Service。
- `mysql-nodeport.yaml`: 对外访问 Service。
- `mysql-statefulSet.yaml`: MySQL StatefulSet。

## 推荐应用顺序

```bash
kubectl diff -f .
kubectl apply -f mysql-secret.yaml
kubectl apply -f mysql-config.yaml
kubectl apply -f mysql-pv.yaml
kubectl apply -f mysql-pvc.yaml
kubectl apply -f mysql-headless.yaml
kubectl apply -f mysql-statefulSet.yaml
kubectl apply -f mysql-nodeport.yaml
```

## 生产检查

- 确认密码、PV 路径、备份和恢复方案。
- 确认 NodePort 或入口访问控制。

## 验证

```bash
kubectl get pod,svc,pv,pvc -A | grep mysql
```
