#  应用接入地址

以后业务应用不要直接写 Tempo，统一写 Alloy。

## OTLP HTTP 推荐配置

```yaml
env:
  - name: OTEL_SERVICE_NAME
    value: order-api
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: http://alloy-otlp.logging.svc.cluster.local:4318
  - name: OTEL_EXPORTER_OTLP_PROTOCOL
    value: http/protobuf
  - name: OTEL_TRACES_EXPORTER
    value: otlp
  - name: OTEL_METRICS_EXPORTER
    value: none
  - name: OTEL_LOGS_EXPORTER
    value: none
```

## OTLP gRPC 配置

```yaml
env:
  - name: OTEL_SERVICE_NAME
    value: order-api
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: http://alloy-otlp.logging.svc.cluster.local:4317
  - name: OTEL_EXPORTER_OTLP_PROTOCOL
    value: grpc
  - name: OTEL_TRACES_EXPORTER
    value: otlp
  - name: OTEL_METRICS_EXPORTER
    value: none
  - name: OTEL_LOGS_EXPORTER
    value: none
```

---

# Java 应用常用配置

如果是 Java Spring Boot，容器里要有 `opentelemetry-javaagent.jar`，然后加：

```yaml
env:
  - name: JAVA_TOOL_OPTIONS
    value: "-javaagent:/otel/opentelemetry-javaagent.jar"
  - name: OTEL_SERVICE_NAME
    value: order-api
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: http://alloy-otlp.logging.svc.cluster.local:4318
  - name: OTEL_EXPORTER_OTLP_PROTOCOL
    value: http/protobuf
  - name: OTEL_TRACES_EXPORTER
    value: otlp
  - name: OTEL_METRICS_EXPORTER
    value: none
  - name: OTEL_LOGS_EXPORTER
    value: none
```

链路就是：

```text
Java 应用
  -> alloy-otlp.logging.svc.cluster.local:4318
  -> Alloy
  -> tempo.tracing.svc.cluster.local:4317
  -> Grafana Tempo 查询
```

---

#  Grafana 里查看

```text
Grafana -> Explore -> Tempo
```

查询服务名：

```text
order-api
```

如果没有数据，优先查：

```bash
kubectl -n logging logs -l app.kubernetes.io/name=alloy --tail=200
kubectl -n tracing logs -l app.kubernetes.io/instance=tempo --tail=200
```

Alloy 同时保留原来的 **日志采集到 Loki**，并新增 **Trace 转发到 Tempo**。


# Grafana / Loki 查询

查全部 host journal 异常日志：

```logql
{cluster="prod-hz-01", job="systemd-journal"}
```

查某个节点：

```logql
{cluster="prod-hz-01", job="systemd-journal", node="worker8"}
```

查 containerd：

```logql
{cluster="prod-hz-01", job="systemd-journal", unit="containerd.service"}
```

查 kubelet：

```logql
{cluster="prod-hz-01", job="systemd-journal", unit="kubelet.service"}
```

查 OOM：

```logql
{cluster="prod-hz-01", job="systemd-journal", unit="containerd.service"} |= "TaskOOM"
```

查 137：

```logql
{cluster="prod-hz-01", job="systemd-journal", unit="containerd.service"} |= "exit_status:137"
```

查 PLEG：

```logql
{cluster="prod-hz-01", job="systemd-journal", unit="kubelet.service"} |= "GenericPLEG"
```

查 kubelet runtime 超时：

```logql
{cluster="prod-hz-01", job="systemd-journal", unit="kubelet.service"} |= "ContainerStatus from runtime service failed"
```

---

# 后续飞书告警 LogQL

containerd OOM：

```logql
count_over_time({cluster="prod-hz-01", job="systemd-journal", unit="containerd.service"} |= "TaskOOM" [5m]) > 0
```

exit 137：

```logql
count_over_time({cluster="prod-hz-01", job="systemd-journal", unit="containerd.service"} |= "exit_status:137" [5m]) > 0
```

kubelet PLEG 异常：

```logql
count_over_time({cluster="prod-hz-01", job="systemd-journal", unit="kubelet.service"} |= "GenericPLEG: Unable to retrieve pods" [5m]) > 0
```

kubelet runtime service 异常：

```logql
count_over_time({cluster="prod-hz-01", job="systemd-journal", unit="kubelet.service"} |= "ContainerStatus from runtime service failed" [5m]) > 0
```

---

这版不会把 kubelet/containerd 全量日志推到 Loki，只会保留类似：

```text
TaskOOM
exit_status:137
GenericPLEG
ContainerStatus from runtime service failed
ListPodSandbox
DeadlineExceeded
context canceled
shim disconnected
```

这类异常关键日志，日志量会小很多。
