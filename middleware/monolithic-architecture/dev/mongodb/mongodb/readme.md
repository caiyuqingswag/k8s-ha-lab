# mongodb

开发环境 MongoDB StatefulSet 部署清单。

## 文件说明

- `mongodb-secret.yaml`: MongoDB 用户和密码。
- `mongodb-pv.yaml`: 静态 PV。
- `mongodb-pvc.yaml`: PVC。
- `mongodb-headless.yaml`: Headless Service。
- `mongodb-nodeport.yaml`: 对外访问 Service。
- `mongodb-statefulSet.yaml`: MongoDB StatefulSet。

## 推荐应用顺序

```bash
kubectl apply -f mongodb-secret.yaml
kubectl apply -f mongodb-pv.yaml
kubectl apply -f mongodb-pvc.yaml
kubectl apply -f mongodb-headless.yaml
kubectl apply -f mongodb-statefulSet.yaml
kubectl apply -f mongodb-nodeport.yaml
```

## 验证

```bash
kubectl get pod,svc,pv,pvc -A | grep mongodb
```
