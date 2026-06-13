# influxdb

生产环境 InfluxDB StatefulSet 部署清单，用于时序数据存储。

## 文件说明

- `influxdb-secret.yaml`: InfluxDB 用户、密码和 token。
- `influxdb-config.yaml`: InfluxDB 配置。
- `influxdb-pv.yaml`: 静态 PV。
- `influxdb-pvc.yaml`: PVC。
- `influxdb-headless.yaml`: Headless Service。
- `influxdb-nodeport.yaml`: 对外访问 Service。
- `influxdb-statefulSet.yaml`: InfluxDB StatefulSet。

## 推荐应用顺序

```bash
kubectl diff -f .
kubectl apply -f influxdb-secret.yaml
kubectl apply -f influxdb-config.yaml
kubectl apply -f influxdb-pv.yaml
kubectl apply -f influxdb-pvc.yaml
kubectl apply -f influxdb-headless.yaml
kubectl apply -f influxdb-statefulSet.yaml
kubectl apply -f influxdb-nodeport.yaml
```

## 生产检查

- 确认 token、保留策略、磁盘容量和备份方案。
- 确认时序数据写入量与资源限制匹配。

## 验证

```bash
kubectl get pod,svc,pv,pvc -A | grep influxdb
```
