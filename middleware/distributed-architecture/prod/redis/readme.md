# Redis HA

该目录提供 Redis 1 master + 2 replica + Sentinel 的生产测试模板。

镜像版本固定为 `redis:8.8.0`。

## 连接方式

业务客户端建议连接 Sentinel：

- Sentinel Service: `redis-sentinel.prod-distributed.svc.cluster.local:26379`
- master name: `mymaster`

普通 `redis` Service 会指向所有 Redis Pod，不适合作为写入入口。

## 部署

```bash
kubectl apply -f middleware/distributed-architecture/prod/redis/
```

## 验证

```bash
kubectl -n prod-distributed rollout status sts/redis --timeout=10m
kubectl -n prod-distributed exec redis-0 -c redis -- redis-cli -a "$REDIS_PASSWORD" info replication
kubectl -n prod-distributed exec redis-0 -c sentinel -- redis-cli -p 26379 sentinel masters
```
