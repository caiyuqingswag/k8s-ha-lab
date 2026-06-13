# 单体架构中间件部署说明

该目录保存单体架构场景下的基础中间件 Kubernetes 清单，按环境分为 `dev`、`sit`、`prod` 三套。

当前组件包括：

- MySQL
- Redis
- MongoDB
- RabbitMQ
- MinIO
- InfluxDB

## 目录结构

```text
middleware/monolithic-architecture/
  dev/       # 开发环境，namespace: dev-basic
  sit/       # 集成测试环境，namespace: sit-basic
  prod/      # 生产环境，namespace: prod-basic
```

每个环境目录下提供 `namespace.yaml`，组件目录内通常包含：

- `*-secret.yaml`: 账号密码。
- `*-config.yaml`: 组件配置，部分组件没有该文件。
- `*-pv.yaml`: 静态 NFS PV。
- `*-pvc.yaml`: PVC。
- `*-headless.yaml`: StatefulSet 使用的 Headless Service。
- `*-statefulSet.yaml`: 单副本 StatefulSet。
- `*-nodeport.yaml`: 对外调试或业务访问用的 NodePort Service。

## 部署顺序

首次部署某个环境时，先创建 namespace：

```bash
kubectl apply -f middleware/monolithic-architecture/dev/namespace.yaml
kubectl apply -f middleware/monolithic-architecture/sit/namespace.yaml
kubectl apply -f middleware/monolithic-architecture/prod/namespace.yaml
```

再按组件部署：

```bash
kubectl apply -f middleware/monolithic-architecture/<env>/<component>/
```

建议生产环境先执行差异检查：

```bash
kubectl diff -f middleware/monolithic-architecture/prod/<component>/
kubectl apply -f middleware/monolithic-architecture/prod/<component>/
```

其中 MongoDB 在 `dev` 和 `prod` 目录下多一层 `mongodb/` 子目录，部署路径分别为：

```bash
kubectl apply -f middleware/monolithic-architecture/dev/mongodb/mongodb/
kubectl apply -f middleware/monolithic-architecture/prod/mongodb/mongodb/
```

## 存储方案

当前清单使用静态 NFS PV，NFS 服务器地址为 `172.16.15.76`，数据目录按环境和组件拆分：

```text
/data/jiyan/dev/<component>
/data/jiyan/sit/<component>
/data/jiyan/prod/<component>
```

该方案适合实验环境、单体应用和中小规模数据量场景，优点是简单、成本低、备份路径清晰。它不等同于高可用存储，生产环境需要额外确认 NFS 服务自身的可用性、备份、恢复演练和容量监控。

## 配置检查项

部署前建议逐项确认：

- namespace 是否已创建。
- NFS server、目录和权限是否正确。
- PV/PVC 的 `storageClassName`、容量和访问模式是否符合实际环境。
- Secret 中的密码是否已替换，当前清单使用 `stringData` 明文保存，生产环境建议改为外部 Secret 管理或 SealedSecret。
- NodePort 是否和集群内已有端口冲突，生产环境是否真的需要直接暴露。
- NodePort/LoadBalancer 当前显式使用 `externalTrafficPolicy: Cluster` 和 `sessionAffinity: None`，适合单副本服务在任意节点入口访问；如果需要保留客户端源 IP，可评估改为 `Local`，但要注意只有运行 Pod 的节点可转发。
- 所有组件当前都是单副本 StatefulSet，不具备组件级高可用能力。
- 镜像版本是否符合当前环境的兼容性和漏洞扫描要求。
- 资源 request/limit 是否符合容量规划。

## 配置优化说明

- MySQL 配置补充了 `max_allowed_packet`、`table_open_cache`、`thread_cache_size`、`innodb_buffer_pool_size`、`innodb_log_file_size` 和严格 SQL 模式，适配当前 4Gi 内存限制下的单体业务场景。
- Redis 配置补充了 AOF preamble、AOF 自动重写阈值、`tcp-backlog` 和默认数据库数量，并保留 `appendfsync everysec` 作为性能和可靠性的折中。
- InfluxDB 配置补充了 HTTP 请求体和返回行数限制，避免单次请求过大拖垮单副本实例。

## 验证命令

```bash
kubectl get ns dev-basic sit-basic prod-basic
kubectl get pv,pvc -A | grep jiyan
kubectl get sts,pod,svc -n <namespace>
kubectl describe pod -n <namespace> <pod-name>
```

## 适用边界

| 场景 | 适合度 |
| --- | --- |
| 本地实验环境 | 适合 |
| 开发/联调环境 | 适合 |
| SIT 集成测试 | 基本适合 |
| 小规模单体生产 | 需补齐备份、监控和访问控制 |
| 强一致、高并发、自动容灾场景 | 不建议直接使用本目录清单 |
