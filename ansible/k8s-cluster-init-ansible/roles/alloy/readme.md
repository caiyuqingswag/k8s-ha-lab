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
