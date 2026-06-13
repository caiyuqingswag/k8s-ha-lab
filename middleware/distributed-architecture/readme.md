# 分布式架构中间件部署说明

该目录保存面向生产测试环境的高可用中间件部署模板，存储层默认使用静态 Local PV 绑定本地 SSD。

当前目标不是把单体清单简单改成 `replicas: 3`，而是按组件真实的高可用方式来组织：

- MinIO: 原生分布式模式，4 副本 StatefulSet。
- RabbitMQ: 3 节点集群，使用 Kubernetes peer discovery。
- Redis: 1 master + 2 replica + Sentinel，业务侧通过 Sentinel 发现 master。
- MySQL: 推荐 MySQL Operator / InnoDBCluster，目录中提供 CR 示例。
- VictoriaMetrics Cluster: 替代 InfluxDB OSS 的免费高可用时序存储方案。
- InfluxDB: OSS 1.x/2.x 不支持简单 StatefulSet active-active，高可用需 InfluxDB Enterprise/Cluster 或改用其他时序方案；本目录不提供“假 HA”清单。

## 镜像版本

当前清单固定使用以下镜像版本，避免 `latest` 标签带来的不可复现：

| 组件 | 镜像 |
| --- | --- |
| MySQL | `8.0.37`，通过 InnoDBCluster `spec.version` 指定 |
| Redis | `redis:8.8.0` |
| RabbitMQ | `rabbitmq:4.3.1-management` |
| MinIO | `minio/minio:RELEASE.2025-09-07T16-13-09Z` |
| VictoriaMetrics Cluster | `victoriametrics/vmstorage:v1.145.0-cluster`、`victoriametrics/vminsert:v1.145.0-cluster`、`victoriametrics/vmselect:v1.145.0-cluster` |

InfluxDB OSS 未提供 HA 清单；如只做单实例验证，建议固定具体版本，例如 `influxdb:2.9.1`，不要使用 `latest`。

## 目录结构

```text
middleware/distributed-architecture/
  prod/
    namespace.yaml
    storage/
      local-ssd-storageclass.yaml
      local-pv/
    minio/
    rabbitmq/
    redis/
    mysql/
    victoriametrics/
    influxdb/
```

## Local PV 规划

当前模板假设 SSD 节点 hostname 为 `ssd1`、`ssd2`、`ssd3`、`ssd4`。最大副本数是 MinIO 的 4 副本，所以准备 4 个 SSD 节点；其他 3 副本组件使用 `ssd1` 到 `ssd3`。

Local PV 路径规划：

```text
ssd1:/data/local-pv/prod-distributed/minio-0
ssd2:/data/local-pv/prod-distributed/minio-1
ssd3:/data/local-pv/prod-distributed/minio-2
ssd4:/data/local-pv/prod-distributed/minio-3

ssd1:/data/local-pv/prod-distributed/rabbitmq-0
ssd2:/data/local-pv/prod-distributed/rabbitmq-1
ssd3:/data/local-pv/prod-distributed/rabbitmq-2

ssd1:/data/local-pv/prod-distributed/redis-0
ssd2:/data/local-pv/prod-distributed/redis-1
ssd3:/data/local-pv/prod-distributed/redis-2

ssd1:/data/local-pv/prod-distributed/vmstorage-0
ssd2:/data/local-pv/prod-distributed/vmstorage-1
ssd3:/data/local-pv/prod-distributed/vmstorage-2

ssd1:/data/local-pv/prod-distributed/mysql-0
ssd2:/data/local-pv/prod-distributed/mysql-1
ssd3:/data/local-pv/prod-distributed/mysql-2
```

这些目录需要在对应节点上提前创建并设置正确权限。PVC 不单独手写文件，而是由 StatefulSet 的 `volumeClaimTemplates` 或 MySQL Operator 的 `datadirVolumeClaimTemplate` 自动创建；模板通过 `storageClassName: local-ssd` 和 selector 绑定对应组件的静态 PV。

## 部署顺序

```bash
kubectl apply -f middleware/distributed-architecture/prod/namespace.yaml
kubectl apply -f middleware/distributed-architecture/prod/storage/local-ssd-storageclass.yaml
kubectl apply -f middleware/distributed-architecture/prod/storage/local-pv/
```

然后按组件目录部署：

```bash
kubectl apply -f middleware/distributed-architecture/prod/minio/
kubectl apply -f middleware/distributed-architecture/prod/rabbitmq/
kubectl apply -f middleware/distributed-architecture/prod/redis/
kubectl apply -f middleware/distributed-architecture/prod/victoriametrics/
```

MySQL 需要先安装 MySQL Operator，再应用 CR：

```bash
kubectl apply -f middleware/distributed-architecture/prod/mysql/mysql-innodbcluster.yaml
```

## StorageClass

`prod/storage/local-ssd-storageclass.yaml` 定义 `local-ssd`：

- `provisioner: kubernetes.io/no-provisioner`
- `volumeBindingMode: WaitForFirstConsumer`
- `reclaimPolicy: Retain`

该方案把数据保存在本地 SSD，性能通常优于网络块存储，但节点损坏时需要依赖组件副本恢复数据。它适合 Redis、RabbitMQ、MinIO、VictoriaMetrics 这类具备副本/集群能力的组件。

## 重要边界

- 多副本 Pod 不等于组件高可用，必须确认组件自身支持集群、复制或故障转移。
- Local PV 绑定具体节点，节点名、目录和权限必须提前准备好。
- Redis 的普通客户端不应直连 `redis` Service 写入，建议通过 Sentinel 获取当前 master。
- MinIO 分布式模式至少 4 个卷，本模板使用 4 副本，每个 Pod 一个 PVC。
- RabbitMQ 集群依赖稳定 DNS、Erlang cookie 和 peer discovery RBAC。
- MySQL 推荐通过 Operator 管理复制、故障转移和备份。
- InfluxDB OSS 不建议在 Kubernetes 里用多个独立 Pod 伪装 HA。

## 验证

```bash
kubectl get pod,svc,pdb -n prod-distributed
kubectl get pv | grep local-ssd
kubectl get pvc -n prod-distributed
kubectl get sc local-ssd
```

组件专项验证见各子目录 README。
