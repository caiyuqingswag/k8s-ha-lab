##  本 role 安装什么？

本 role 安装：

```text
kiali-operator namespace:
  kiali-operator

istio-system namespace:
  Kiali CR
  kiali deployment
  kiali service
````

采用 Operator 模式：

```text
Helm 安装 kiali-operator
Kiali Operator 根据 Kiali CR 创建 Kiali Server
```

## Helm 包位置

```text
roles/kiali/files/kiali-operator-2.21.0.tgz
```

下载地址：

```text
https://kiali.org/helm-charts/kiali-operator-2.21.0.tgz
```

## 核心配置

文件：

```text
roles/kiali/defaults/main.yml
```

主要配置：

```yaml
kiali_hostname: "kiali.itexcloud.com"
kiali_auth_strategy: "anonymous"
kiali_prometheus_url: "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090"
kiali_grafana_internal_url: "http://grafana.monitoring.svc.cluster.local"
kiali_grafana_external_url: "https://grafana.itexcloud.com"
```

## 访问方式

建议走 Istio internal gateway：

```text
https://kiali.itexcloud.com
  -> 内部/白名单 CLB
  -> istio-ingressgateway-internal
  -> kiali.istio-system.svc.cluster.local:20001
```

## 添加 Istio internal route

修改：

```text
roles/istio-routes-internal/defaults/main.yml
```

在 `istio_internal_routes` 里追加：

```yaml
  - name: kiali
    namespace: istio-system
    host: kiali.itexcloud.com
    serviceHost: kiali.istio-system.svc.cluster.local
    servicePort: 20001
```

然后执行：

```bash
ansible-playbook -i inventory.ini site.yml --tags istio-routes-internal
```

## 安装 Kiali

```bash
ansible-playbook -i inventory.ini site.yml --tags kiali
```

检查：

```bash
kubectl -n kiali-operator get pods -o wide
kubectl -n istio-system get pods -l app.kubernetes.io/name=kiali -o wide
kubectl -n istio-system get svc kiali -o wide
kubectl -n istio-system get kiali
```

## 验证 Prometheus

Kiali 依赖 Prometheus 指标。

检查 Prometheus 服务：

```bash
kubectl -n monitoring get svc | grep prometheus
```

默认配置：

```text
http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090
```

如果 Prometheus service 名称不同，需要修改：

```yaml
kiali_prometheus_url
```

##  验证 Grafana

默认配置：

```yaml
kiali_grafana_enabled: true
kiali_grafana_internal_url: "http://grafana.monitoring.svc.cluster.local"
kiali_grafana_external_url: "https://grafana.itexcloud.com"
```

如果 Grafana service 名称不同，查看：

```bash
kubectl -n monitoring get svc | grep grafana
```

然后修改：

```yaml
kiali_grafana_internal_url
```

## 认证方式

当前默认：

```yaml
kiali_auth_strategy: "anonymous"
```

这表示打开 Kiali 不需要登录。

只建议在以下场景使用：

```text
内网访问
VPN 访问
CLB 白名单访问
公司办公出口 IP 白名单
```

不要公网裸露 anonymous Kiali。

如果后面要加强认证，可以改成：

```yaml
kiali_auth_strategy: "token"
```

然后使用 Kubernetes token 登录。

## Kiali 里怎么看灰度？

进入 Kiali 后：

```text
左侧 Graph
选择 Namespace
Display 选择：
  Traffic
  Traffic Animation
  Security
  Response Time
  Request Percentage
```

如果配置了 VirtualService 90/10 灰度，Kiali Graph 里可以看到两个版本的流量比例。

前提是服务有版本 label，例如：

```yaml
labels:
  app: order-api
  version: v1
```

和：

```yaml
labels:
  app: order-api
  version: v2
```

## 12. Kiali 里怎么看 mTLS？

Graph 页面打开：

```text
Display -> Security
```

如果 mTLS 正常，会看到安全锁标识。

也可以命令行检查：

```bash
istioctl authn tls-check
```

## 常见问题

###  Kiali 页面空白，没有流量

可能原因：

```text
业务没有经过 Istio sidecar
Pod 没有注入 istio-proxy
没有真实访问流量
Prometheus 地址不对
Istio telemetry 指标没有采集
```

检查：

```bash
kubectl -n prod-itex-servers get pods
```

应该看到：

```text
READY 2/2
```

###  Kiali 报 Prometheus 不可用

检查：

```bash
kubectl -n monitoring get svc | grep prometheus
kubectl -n istio-system logs deploy/kiali --tail=100
```

确认 `kiali_prometheus_url` 正确。

### Kiali 报 Grafana 不可用

检查：

```bash
kubectl -n monitoring get svc | grep grafana
kubectl -n istio-system logs deploy/kiali --tail=100
```

确认：

```yaml
kiali_grafana_internal_url
```

正确。

### Kiali 看不到业务 namespace

本 role 配置了：

```yaml
accessible_namespaces:
  - "**"
```

理论上可以看所有 namespace。

如果看不到，检查 Kiali CR：

```bash
kubectl -n istio-system get kiali kiali -o yaml
```

### Kiali Pod 起不来

查看：

```bash
kubectl -n istio-system describe pod -l app.kubernetes.io/name=kiali
kubectl -n istio-system logs deploy/kiali --tail=200
kubectl -n kiali-operator logs deploy/kiali-operator --tail=200
```

## 后续接 Tempo

等部署 Tempo 后，可以打开：

```yaml
kiali_tracing_enabled: true
kiali_tracing_internal_url: "http://tempo.tracing.svc.cluster.local:3200"
kiali_tracing_external_url: "https://tempo.itexcloud.com"
```

然后重跑：

```bash
ansible-playbook -i inventory.ini site.yml --tags kiali
```

## 卸载

删除 Kiali CR：

```bash
kubectl -n istio-system delete kiali kiali
```

卸载 Operator：

```bash
helm uninstall kiali-operator -n kiali-operator --kubeconfig /etc/kubernetes/admin.conf
```

删除 namespace：

```bash
kubectl delete ns kiali-operator
```


# 给 Istio internal route 加 Kiali

修改：

```text
roles/istio-routes-internal/defaults/main.yml
```

在 `istio_internal_routes:` 下面加：

```yaml
  - name: kiali
    namespace: istio-system
    host: kiali.itexcloud.com
    serviceHost: kiali.istio-system.svc.cluster.local
    servicePort: 20001
```

然后执行：

```bash
ansible-playbook -i inventory.ini site.yml --tags istio-routes-internal
```

---

# 安装执行


安装：

```bash
ansible-playbook -i inventory.ini site.yml --tags kiali
```

检查：

```bash
kubectl -n kiali-operator get pods -o wide
kubectl -n istio-system get pods -l app.kubernetes.io/name=kiali -o wide
kubectl -n istio-system get svc kiali -o wide
kubectl -n istio-system get kiali
```

访问：

```text
https://kiali.itexcloud.com
```



