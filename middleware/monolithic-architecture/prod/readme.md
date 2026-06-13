# prod

该目录保存生产环境中间件清单。生产部署前需要重点确认存储、备份、资源限制、访问控制和变更窗口。

## 组件

- `mysql`
- `redis`
- `rabbit`
- `minio`
- `influxdb`
- `mongodb`

## 使用方式

建议先审查清单，再分步骤应用：

```bash
kubectl diff -f middleware/monolithic-architecture/prod/<component>/
kubectl apply -f middleware/monolithic-architecture/prod/<component>/
```

## 生产检查项

- Secret 是否已替换为生产密码。
- PV/PVC 是否指向可靠存储。
- 资源 request/limit 是否符合容量规划。
- NodePort、Service、DNS 和访问白名单是否正确。
- 是否已有备份、恢复演练和监控告警。
- StatefulSet 升级策略是否符合维护窗口要求。
