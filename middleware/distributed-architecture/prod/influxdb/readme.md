# InfluxDB HA

InfluxDB OSS 1.x/2.x 不能通过普通 StatefulSet 多副本实现真正高可用写入。

如只做单实例验证，建议固定具体镜像版本，例如 `influxdb:2.9.1`，不要使用 `latest`。

可选方案：

- 使用 InfluxDB Enterprise / InfluxDB Cluster。
- 使用云托管时序数据库。
- 改用 VictoriaMetrics、Mimir、Thanos 等更适合 Kubernetes 横向扩展的时序/指标方案。
- 如果仍使用 OSS 单实例，只能依赖 Longhorn 副本、快照、备份和快速重建，不应标记为应用层 HA。

因此本目录暂不提供 InfluxDB OSS 多副本清单，避免生产测试阶段误判可用性。
