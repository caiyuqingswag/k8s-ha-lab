# 分布式架构中间件部署说明

该目录保存面向生产测试环境的高可用中间件部署模板，存储层默认基于 Longhorn。

当前目标不是把单体清单简单改成 `replicas: 3`，而是按组件真实的高可用方式来组织：

- MinIO: 原生分布式模式，4 副本 StatefulSet。
- RabbitMQ: 3 节点集群，使用 Kubernetes peer discovery。
- Redis: 1 master + 2 replica + Sentinel，业务侧通过 Sentinel 发现 master。
- MySQL: 推荐 MySQL Operator / InnoDBCluster，目录中提供 CR 示例。
- InfluxDB: OSS 1.x/2.x 不支持简单 StatefulSet active-active，高可用需 InfluxDB Enterprise/Cluster 或改用其他时序方案；本目录不提供“假 HA”清单。

## 镜像版本

当前清单固定使用以下镜像版本，避免 `latest` 标签带来的不可复现：

| 组件 | 镜像 |
| --- | --- |
| MySQL | `8.0.37`，通过 InnoDBCluster `spec.version` 指定 |
| Redis | `redis:8.8.0` |
| RabbitMQ | `rabbitmq:4.3.1-management` |
| MinIO | `minio/minio:RELEASE.2025-09-07T16-13-09Z` |

InfluxDB OSS 未提供 HA 清单；如只做单实例验证，建议固定具体版本，例如 `influxdb:2.9.1`，不要使用 `latest`。

## 目录结构

```text
middleware/distributed-architecture/
  prod/
    namespace.yaml
    storage/longhorn-storageclass.yaml
    minio/
    rabbitmq/
    redis/
    mysql/
    influxdb/
```

## 部署顺序

```bash
kubectl apply -f middleware/distributed-architecture/prod/namespace.yaml
kubectl apply -f middleware/distributed-architecture/prod/storage/longhorn-storageclass.yaml
```

然后按组件目录部署：

```bash
kubectl apply -f middleware/distributed-architecture/prod/minio/
kubectl apply -f middleware/distributed-architecture/prod/rabbitmq/
kubectl apply -f middleware/distributed-architecture/prod/redis/
```

MySQL 需要先安装 MySQL Operator，再应用 CR：

```bash
kubectl apply -f middleware/distributed-architecture/prod/mysql/mysql-innodbcluster.yaml
```

## StorageClass

`prod/storage/longhorn-storageclass.yaml` 定义 `longhorn-ha`：

- `numberOfReplicas: "3"`
- `dataLocality: best-effort`
- `reclaimPolicy: Retain`
- `allowVolumeExpansion: true`

该 StorageClass 适合生产测试环境。正式生产前还需要配置 Longhorn 备份目标、磁盘调度策略、容量告警和快照策略。

## 重要边界

- 多副本 Pod 不等于组件高可用，必须确认组件自身支持集群、复制或故障转移。
- Redis 的普通客户端不应直连 `redis` Service 写入，建议通过 Sentinel 获取当前 master。
- MinIO 分布式模式至少 4 个卷，本模板使用 4 副本，每个 Pod 一个 PVC。
- RabbitMQ 集群依赖稳定 DNS、Erlang cookie 和 peer discovery RBAC。
- MySQL 推荐通过 Operator 管理复制、故障转移和备份。
- InfluxDB OSS 不建议在 Kubernetes 里用多个独立 Pod 伪装 HA。

## 验证

```bash
kubectl get pod,svc,pdb -n prod-distributed
kubectl get pvc -n prod-distributed
kubectl get sc longhorn-ha
```

组件专项验证见各子目录 README。
