# sit

该目录保存 SIT 集成测试环境中间件清单，用于业务联调、集成测试和发布前验证。

## 组件

- `mysql`
- `redis`
- `rabbit`
- `minio`
- `influxdb`
- `mongodb`

## 使用方式

```bash
kubectl apply -f middleware/monolithic-architecture/sit/<component>/
```

## 注意事项

- SIT 环境应尽量贴近生产的配置、账号权限和网络访问方式。
- 部署前确认测试数据初始化、备份恢复和清理策略。
- 如需暴露 NodePort，避免和 dev/prod 环境端口冲突。
