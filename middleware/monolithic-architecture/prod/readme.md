# prod

该目录保存生产环境中间件清单。生产部署前需要重点确认存储、备份、资源限制、访问控制和变更窗口。

- namespace: `prod-basic`
- NFS 根目录: `/data/jiyan/prod`
- NFS server: `172.16.15.76`

## 组件

- `mysql`
- `redis`
- `rabbit`
- `minio`
- `influxdb`
- `mongodb`

## 使用方式

首次部署先创建 namespace：

```bash
kubectl apply -f middleware/monolithic-architecture/prod/namespace.yaml
```

建议先审查清单，再分步骤应用：

```bash
kubectl diff -f middleware/monolithic-architecture/prod/<component>/
kubectl apply -f middleware/monolithic-architecture/prod/<component>/
```

MongoDB 当前资源位于多一层子目录：

```bash
kubectl diff -f middleware/monolithic-architecture/prod/mongodb/mongodb/
kubectl apply -f middleware/monolithic-architecture/prod/mongodb/mongodb/
```

## 生产检查项

- Secret 是否已替换为生产密码，是否需要改为外部 Secret 管理或 SealedSecret。
- PV/PVC 是否指向可靠存储，NFS 服务本身是否具备备份和恢复能力。
- 资源 request/limit 是否符合容量规划。
- NodePort、LoadBalancer、Service、DNS 和访问白名单是否正确。
- NodePort/LoadBalancer 当前显式使用 `externalTrafficPolicy: Cluster`，优先保证单副本服务从任意节点可访问；如生产需要保留客户端源 IP，再评估改为 `Local`。
- 是否已有备份、恢复演练、监控告警和容量告警。
- StatefulSet 升级策略是否符合维护窗口要求。
- 当前清单仍是单副本部署，不等同于中间件高可用集群。
