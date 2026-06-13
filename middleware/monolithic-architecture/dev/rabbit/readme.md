# rabbit

开发环境 RabbitMQ StatefulSet 部署清单。

## 文件说明

- `rabbitmq-secret.yaml`: RabbitMQ 用户和密码。
- `rabbitmq-pv.yaml`: 静态 PV。
- `rabbitmq-pvc.yaml`: PVC。
- `rabbitmq-headless.yaml`: Headless Service。
- `rabbitmq-nodeport.yaml`: 对外访问 Service。
- `rabbitmq-statefulSet.yaml`: RabbitMQ StatefulSet。

## 推荐应用顺序

```bash
kubectl apply -f rabbitmq-secret.yaml
kubectl apply -f rabbitmq-pv.yaml
kubectl apply -f rabbitmq-pvc.yaml
kubectl apply -f rabbitmq-headless.yaml
kubectl apply -f rabbitmq-statefulSet.yaml
kubectl apply -f rabbitmq-nodeport.yaml
```

## 验证

```bash
kubectl get pod,svc,pv,pvc -A | grep rabbit
```
