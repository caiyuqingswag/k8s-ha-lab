# Redis HA

该目录提供 Redis 1 master + 2 replica + Sentinel 的生产测试模板，数据卷使用 `local-ssd` 静态 Local PV。

镜像版本固定为 `redis:8.8.0`。

## 连接方式

业务客户端建议连接 Sentinel：

- Sentinel Service: `redis-sentinel.prod-distributed.svc.cluster.local:26379`
- master name: `mymaster`

普通 `redis` Service 会指向所有 Redis Pod，不适合作为写入入口。

## 部署

先确认以下目录已在对应节点创建：

```text
ssd1:/data/local-pv/prod-distributed/redis-0
ssd2:/data/local-pv/prod-distributed/redis-1
ssd3:/data/local-pv/prod-distributed/redis-2
```

```bash
kubectl apply -f middleware/distributed-architecture/prod/redis/
```

## 验证

```bash
kubectl -n prod-distributed rollout status sts/redis --timeout=10m
kubectl -n prod-distributed exec redis-0 -c redis -- redis-cli -a "$REDIS_PASSWORD" info replication
kubectl -n prod-distributed exec redis-0 -c sentinel -- redis-cli -p 26379 sentinel masters
```
