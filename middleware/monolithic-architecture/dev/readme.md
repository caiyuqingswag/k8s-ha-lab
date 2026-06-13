# dev

该目录保存开发环境中间件清单，用于快速搭建开发联调所需的基础服务。

- namespace: `dev-basic`
- NFS 根目录: `/data/jiyan/dev`
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
kubectl apply -f middleware/monolithic-architecture/dev/namespace.yaml
```

再部署单个组件：

```bash
kubectl apply -f middleware/monolithic-architecture/dev/<component>/
```

MongoDB 当前资源位于多一层子目录：

```bash
kubectl apply -f middleware/monolithic-architecture/dev/mongodb/mongodb/
```

## 注意事项

- 开发环境优先保证启动便利，资源、副本和存储规格不代表生产标准。
- 部署前检查 NodePort、PV 路径和 Secret 是否和本地环境冲突。
- 当前 Secret 使用 `stringData` 明文保存，提交前注意不要放入真实生产密码。
- 所有组件当前都是单副本 StatefulSet。
- NodePort 显式使用 `externalTrafficPolicy: Cluster`，便于从任意节点入口访问单副本服务。
