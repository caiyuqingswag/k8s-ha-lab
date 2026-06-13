# VictoriaMetrics Cluster HA

该目录提供 VictoriaMetrics Cluster 高可用时序存储模板，用于替代 InfluxDB OSS 单节点方案。

## 架构

- `vmstorage`: 3 副本 StatefulSet，负责持久化存储，使用 `local-ssd` 静态 Local PV。
- `vminsert`: 2 副本 Deployment，负责写入入口。
- `vmselect`: 2 副本 Deployment，负责查询入口。
- `replicationFactor`: 2，写入数据保存到两个 `vmstorage` 节点。

## 镜像

- `victoriametrics/vmstorage:v1.145.0-cluster`
- `victoriametrics/vminsert:v1.145.0-cluster`
- `victoriametrics/vmselect:v1.145.0-cluster`

## 部署

```bash
kubectl apply -f middleware/distributed-architecture/prod/namespace.yaml
kubectl apply -f middleware/distributed-architecture/prod/storage/local-ssd-storageclass.yaml
kubectl apply -f middleware/distributed-architecture/prod/storage/local-pv/vmstorage-pv.yaml
kubectl apply -f middleware/distributed-architecture/prod/victoriametrics/
```

先确认以下目录已在对应节点创建：

```text
ssd1:/data/local-pv/prod-distributed/vmstorage-0
ssd2:/data/local-pv/prod-distributed/vmstorage-1
ssd3:/data/local-pv/prod-distributed/vmstorage-2
```

## 访问

- 写入入口: `http://vminsert.prod-distributed.svc.cluster.local:8480`
- 查询入口: `http://vmselect.prod-distributed.svc.cluster.local:8481`

Prometheus remote_write 地址：

```text
http://vminsert.prod-distributed.svc.cluster.local:8480/insert/0/prometheus/api/v1/write
```

InfluxDB line protocol 写入地址：

```text
http://vminsert.prod-distributed.svc.cluster.local:8480/insert/0/influx/write
```

Prometheus 查询地址：

```text
http://vmselect.prod-distributed.svc.cluster.local:8481/select/0/prometheus
```

## 验证

```bash
kubectl -n prod-distributed get pod -l app.kubernetes.io/part-of=victoriametrics
kubectl -n prod-distributed get pvc -l app.kubernetes.io/name=vmstorage
kubectl -n prod-distributed rollout status sts/vmstorage --timeout=10m
kubectl -n prod-distributed rollout status deploy/vminsert --timeout=5m
kubectl -n prod-distributed rollout status deploy/vmselect --timeout=5m
```

## 注意

- VictoriaMetrics 支持 InfluxDB line protocol 写入，但查询模型主要是 PromQL/MetricsQL，不是完整 InfluxQL 平替。
- `vmstorage` 需要至少 3 个可调度节点，因为配置了强反亲和。
- 生产环境需要补充备份、监控告警、容量规划和保留周期策略。
