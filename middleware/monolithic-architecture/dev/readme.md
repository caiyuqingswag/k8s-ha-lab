# dev

该目录保存开发环境中间件清单，用于快速搭建开发联调所需的基础服务。

## 组件

- `mysql`
- `redis`
- `rabbit`
- `minio`
- `influxdb`
- `mongodb`

## 使用方式

按组件目录进入后执行：

```bash
kubectl apply -f .
```

或按资源依赖顺序逐个应用 Secret、ConfigMap、PV、PVC、Service、StatefulSet。

## 注意事项

- 开发环境优先保证启动便利，资源、副本和存储规格可能不适合生产。
- 部署前检查命名空间、NodePort、PV 路径是否和本地环境冲突。
- 账号密码和端口请按实际开发环境调整。
