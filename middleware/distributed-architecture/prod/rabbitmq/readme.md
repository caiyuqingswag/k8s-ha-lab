# RabbitMQ HA

该目录提供 3 节点 RabbitMQ 集群，使用 Kubernetes peer discovery 自动组集群，数据卷使用 `local-ssd` 静态 Local PV。

镜像版本固定为 `rabbitmq:4.3.1-management`。

## 部署

先确认以下目录已在对应节点创建：

```text
ssd1:/data/local-pv/prod-distributed/rabbitmq-0
ssd2:/data/local-pv/prod-distributed/rabbitmq-1
ssd3:/data/local-pv/prod-distributed/rabbitmq-2
```

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
