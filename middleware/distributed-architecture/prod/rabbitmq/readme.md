# RabbitMQ HA

该目录提供 3 节点 RabbitMQ 集群，使用 Kubernetes peer discovery 自动组集群。

镜像版本固定为 `rabbitmq:4.3.1-management`。

## 部署

```bash
kubectl apply -f middleware/distributed-architecture/prod/rabbitmq/
```

## 验证

```bash
kubectl -n prod-distributed rollout status sts/rabbitmq --timeout=10m
kubectl -n prod-distributed exec rabbitmq-0 -- rabbitmq-diagnostics cluster_status
kubectl -n prod-distributed get endpoints rabbitmq-headless
```

业务连接建议使用 `rabbitmq.prod-distributed.svc.cluster.local:5672`，管理端口建议通过受控 Ingress/Gateway 暴露。
