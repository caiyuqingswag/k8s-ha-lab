# sit

该目录保存 SIT 集成测试环境中间件清单，用于业务联调、集成测试和发布前验证。

- namespace: `sit-basic`
- NFS 根目录: `/data/jiyan/sit`
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
kubectl apply -f middleware/monolithic-architecture/sit/namespace.yaml
```

再部署单个组件：

```bash
kubectl apply -f middleware/monolithic-architecture/sit/<component>/
```

## 注意事项

- SIT 环境应尽量贴近生产的配置、账号权限和网络访问方式。
- 部署前确认测试数据初始化、备份恢复和清理策略。
- 如需暴露 NodePort 或 LoadBalancer，避免和 dev/prod 环境端口冲突。
- 所有组件当前都是单副本 StatefulSet，不用于验证组件级高可用。
- NodePort/LoadBalancer 显式使用 `externalTrafficPolicy: Cluster`，便于单副本服务在任意节点入口访问。
