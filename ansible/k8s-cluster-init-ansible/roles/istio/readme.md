```text
单集群当前：
CLB公网     -> istio-ingressgateway-public   -> 业务服务
CLB内网白名单 -> istio-ingressgateway-internal -> Grafana / Argo CD / Longhorn / Prometheus
业务服务间   -> Istio Sidecar 做灰度、熔断、重试、mTLS

后续多集群：
每个集群都部署同样的 istio base / istiod / public gateway / internal gateway
再启用 east-west gateway
再做 remote secret 互联
```

Istio 官方 Helm 安装顺序就是 `base -> istiod -> gateway`，其中 `base` 安装 CRD，`istiod` 是控制面，`gateway` 是入口网关；Istio release 包也包含 `istioctl`、Helm charts 和 samples。([Istio][1])

---

## 1. 下载地址

当前查到 Istio 最新 release 是 **1.29.2**。GitHub release 里有 `istio-1.29.2-linux-amd64.tar.gz`，Istio 官方文档也示例了下载 1.29.2。([GitHub][2])

### 必须下载这 3 个 Helm Chart

```text
https://istio-release.storage.googleapis.com/charts/base-1.29.2.tgz
```

```text
https://istio-release.storage.googleapis.com/charts/istiod-1.29.2.tgz
```

```text
https://istio-release.storage.googleapis.com/charts/gateway-1.29.2.tgz
```

## 2. 执行安装


```bash
ansible-playbook -i inventory.ini site.yml --tags istio
```

检查：

```bash
kubectl -n istio-system get pods -o wide
kubectl -n istio-ingress-public get pods,svc -o wide
kubectl -n istio-ingress-internal get pods,svc -o wide
istioctl version
```

期望 NodePort：

```text
istio-ingress-public     80:30080/TCP  443:30443/TCP
istio-ingress-internal   80:30081/TCP  443:30444/TCP
```

---

## 3. 腾讯云 CLB 对接

公网 CLB：

```text
监听：443 HTTPS
证书：公网业务证书
后端：NodeIP:30080
后端协议：HTTP
用途：业务域名
```

内部/白名单 CLB：

```text
监听：443 HTTPS
证书：*.itexcloud.com
后端：NodeIP:30081
后端协议：HTTP
访问控制：公司出口 IP / VPN 网段
用途：Grafana / Argo CD / Prometheus / Longhorn / Rancher
```

---

## 4. 使用方法：给业务 namespace 开 sidecar

例如：

```bash
kubectl label namespace prod-paas-components istio-injection=enabled --overwrite
```

然后重启业务 Deployment：

```bash
kubectl -n prod-paas-components rollout restart deploy
```

检查 Pod 是否变成 `2/2`：

```bash
kubectl -n prod-paas-components get pods
```

如果看到：

```text
READY 2/2
```

说明应用容器旁边已经注入了 `istio-proxy` sidecar。

---

## 5. 内部 UI 入口示例：Grafana

```bash
cat > /tmp/grafana-istio-route.yaml <<'EOF'
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: internal-gateway
  namespace: istio-ingress-internal
spec:
  selector:
    istio: ingressgateway-internal
  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - grafana.itexcloud.com
        - argocd.itexcloud.com
        - prometheus.itexcloud.com
        - alertmanager.itexcloud.com
        - longhorn.itexcloud.com
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: grafana
  namespace: monitoring
spec:
  hosts:
    - grafana.itexcloud.com
  gateways:
    - istio-ingress-internal/internal-gateway
  http:
    - route:
        - destination:
            host: grafana.monitoring.svc.cluster.local
            port:
              number: 80
EOF

kubectl apply -f /tmp/grafana-istio-route.yaml
```

访问链路：

```text
https://grafana.itexcloud.com
  -> 内部/白名单 CLB
  -> NodeIP:30081
  -> istio-ingressgateway-internal
  -> monitoring/grafana:80
```

---

## 6. 业务公网入口示例

```bash
cat > /tmp/decision-istio-route.yaml <<'EOF'
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: public-gateway
  namespace: istio-ingress-public
spec:
  selector:
    istio: ingressgateway-public
  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - decision.itexcloud.com
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: decision-prod-route
  namespace: prod-paas-components
spec:
  hosts:
    - decision.itexcloud.com
  gateways:
    - istio-ingress-public/public-gateway
  http:
    - match:
        - uri:
            prefix: /
      route:
        - destination:
            host: decision-flow-web.prod-paas-components.svc.cluster.local
            port:
              number: 80
EOF

kubectl apply -f /tmp/decision-istio-route.yaml
```

---

## 7. 灰度发布示例

假设你的服务有两个版本：

```text
decision-flow-web v1
decision-flow-web v2
```

Pod label 类似：

```yaml
version: v1
```

和：

```yaml
version: v2
```

创建 `DestinationRule` + `VirtualService`：

```bash
cat > /tmp/decision-canary.yaml <<'EOF'
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: decision-flow-web
  namespace: prod-paas-components
spec:
  host: decision-flow-web.prod-paas-components.svc.cluster.local
  subsets:
    - name: v1
      labels:
        version: v1
    - name: v2
      labels:
        version: v2
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: decision-flow-web
  namespace: prod-paas-components
spec:
  hosts:
    - decision.itexcloud.com
  gateways:
    - istio-ingress-public/public-gateway
  http:
    - route:
        - destination:
            host: decision-flow-web.prod-paas-components.svc.cluster.local
            subset: v1
            port:
              number: 80
          weight: 90
        - destination:
            host: decision-flow-web.prod-paas-components.svc.cluster.local
            subset: v2
            port:
              number: 80
          weight: 10
EOF

kubectl apply -f /tmp/decision-canary.yaml
```

这就是：

```text
90% 流量到 v1
10% 流量到 v2
```

---

## 8. 重试 / 超时 / 熔断示例

```bash
cat > /tmp/decision-resilience.yaml <<'EOF'
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: decision-flow-web-resilience
  namespace: prod-paas-components
spec:
  host: decision-flow-web.prod-paas-components.svc.cluster.local
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 100
        maxRequestsPerConnection: 10
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 10s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: decision-flow-web-resilience
  namespace: prod-paas-components
spec:
  hosts:
    - decision-flow-web.prod-paas-components.svc.cluster.local
  http:
    - timeout: 3s
      retries:
        attempts: 3
        perTryTimeout: 1s
        retryOn: 5xx,connect-failure,refused-stream
      route:
        - destination:
            host: decision-flow-web.prod-paas-components.svc.cluster.local
            port:
              number: 80
EOF

kubectl apply -f /tmp/decision-resilience.yaml
```

---

## 9. 后续扩展第二、第三个集群怎么做

现在单集群配置：

```yaml
istio_cluster_name: "prod-hz-01"
istio_network_name: "network-hz"
istio_mesh_id: "prod-mesh"
istio_enable_eastwest_gateway: false
```

以后第二个集群 `prod-sh-01`：

```yaml
istio_cluster_name: "prod-sh-01"
istio_network_name: "network-sh"
istio_mesh_id: "prod-mesh"
istio_enable_eastwest_gateway: true
```

第三个集群 `prod-bj-01`：

```yaml
istio_cluster_name: "prod-bj-01"
istio_network_name: "network-bj"
istio_mesh_id: "prod-mesh"
istio_enable_eastwest_gateway: true
```

每个集群都跑同一个 role：

```bash
ansible-playbook -i inventory-prod-sh.ini site.yml --tags istio
ansible-playbook -i inventory-prod-bj.ini site.yml --tags istio
```

后续多集群真正互通时，还需要做两件事：

```text
1. 统一 root CA / trust
2. 交换 remote secret
```

典型命令是：

```bash
istioctl create-remote-secret \
  --name=prod-hz-01 \
  --context=prod-hz-01 \
  | kubectl --context=prod-sh-01 apply -f -
```

反向也要做：

```bash
istioctl create-remote-secret \
  --name=prod-sh-01 \
  --context=prod-sh-01 \
  | kubectl --context=prod-hz-01 apply -f -
```

这部分等你真的有第二个集群时，我再给你单独做 `roles/istio-multicluster`，因为它需要多个 kubeconfig context，不适合现在单集群阶段硬写死。



---

## 最终

现在先只跑：

```text
istio base
istiod
public ingressgateway
internal ingressgateway
```

先不要开 east-west gateway，也不要全 namespace 注入 sidecar。

上线顺序：

```text
1. 安装 Istio
2. 建 internal Gateway，打通 Grafana / Argo CD
3. 建 public Gateway，打通一个测试业务域名
4. 只给一个测试 namespace 开 sidecar
5. 测试灰度 / 重试 / 熔断
6. 再逐步迁业务 namespace
```