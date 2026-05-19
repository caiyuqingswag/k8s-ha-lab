# 6. 执行

```bash
ansible-playbook -i inventory.ini site.yml --tags istio-global-ratelimit
```

检查：

```bash
kubectl -n istio-ratelimit get pods,svc -o wide
kubectl get envoyfilter -A | grep ratelimit
```

查看生成文件：

```bash
cat /etc/kubernetes/istio-global-ratelimit/global-ratelimit.yaml
```

---

# 7. 使用说明 MD

````powershell
@'
# Istio Global Rate Limit 使用说明

## 1. 这是什么？

`istio-global-ratelimit` 是基于 Istio EnvoyFilter + Envoy RateLimit Service + Redis 的全局限流方案。

流量路径：

```text
Client
  -> Istio IngressGateway / Sidecar Envoy
  -> Envoy RateLimit Filter
  -> ratelimit service
  -> Redis
````

如果超过限流阈值，Envoy 返回：

```text
HTTP 429 Too Many Requests
```

## 2. 和本地限流的区别

### 本地限流 Local Rate Limit

每个 Envoy 独立计数。

例如：

```text
gateway 有 3 个副本
每个副本限制 1000 QPS
整体大约 3000 QPS
```

### 全局限流 Global Rate Limit

多个 Envoy 共享 Redis 计数。

例如：

```text
gateway 有 3 个副本
全局限制 1000 QPS
整体就是 1000 QPS
```

## 3. 中大厂怎么用？

常见是两层一起用：

```text
本地限流：
  保护单个 Pod / 单个 Gateway 副本

全局限流：
  保护整体业务配额
  按域名、接口、用户、IP、租户做统一限流
```

推荐架构：

```text
CLB
  -> Istio Gateway
      -> 本地限流兜底
      -> 全局限流做业务配额
      -> Service
          -> Sidecar 本地限流保护单 Pod
```

## 4. 当前 role 默认做了什么？

默认安装：

```text
namespace: istio-ratelimit

Deployment:
  ratelimit-redis
  ratelimit

Service:
  ratelimit-redis
  ratelimit

ConfigMap:
  ratelimit-config

EnvoyFilter:
  public-gateway-global-ratelimit
  internal-gateway-global-ratelimit
```

默认启用：

```text
public gateway 全局 3000 QPS
internal gateway 全局 1000 QPS
```

默认未启用：

```text
order-api 服务级全局限流
```

## 5. 核心配置在哪里？

文件：

```text
roles/istio-global-ratelimit/defaults/main.yml
```

核心变量：

```yaml
istio_global_ratelimit_policies:
  - name: public-gateway-global-ratelimit
    namespace: istio-ingress-public
    context: GATEWAY
    workloadSelector:
      istio: ingressgateway-public
    portNumber: 80
    domain: public-gateway
    descriptorValue: public-gateway
    requestsPerUnit: 3000
    unit: SECOND
```

## 6. 字段解释

### name

生成的 EnvoyFilter 名称。

```yaml
name: public-gateway-global-ratelimit
```

### namespace

EnvoyFilter 所在 namespace。

Gateway 限流写 gateway 所在 namespace：

```yaml
namespace: istio-ingress-public
```

服务级限流写业务服务所在 namespace：

```yaml
namespace: prod-itex-servers
```

### context

限流位置：

```yaml
context: GATEWAY
```

表示作用在 Istio Gateway。

```yaml
context: SIDECAR_INBOUND
```

表示作用在业务 Pod 入站 sidecar。

### workloadSelector

匹配目标 Pod 的 label。

公网 Gateway：

```yaml
workloadSelector:
  istio: ingressgateway-public
```

业务服务：

```yaml
workloadSelector:
  app: order-api
```

### portNumber

监听端口。

Gateway HTTP：

```yaml
portNumber: 80
```

业务服务：

```yaml
portNumber: 80
```

### domain

RateLimit Service 里的限流域。

```yaml
domain: public-gateway
```

EnvoyFilter 和 ratelimit config 必须一致。

### descriptorValue

限流描述符值。

```yaml
descriptorValue: public-gateway
```

当前模板使用 generic_key：

```yaml
generic_key: public-gateway
```

### requestsPerUnit

单位时间内允许请求数。

```yaml
requestsPerUnit: 3000
```

### unit

单位：

```text
SECOND
MINUTE
HOUR
DAY
```

例如：

```yaml
requestsPerUnit: 3000
unit: SECOND
```

表示：

```text
每秒 3000 次
```

```yaml
requestsPerUnit: 10000
unit: MINUTE
```

表示：

```text
每分钟 10000 次
```

## 7. 如何新增一个服务级全局限流？

例如给 `user-api` 设置全局 2000 QPS：

```yaml
- name: user-api-global-ratelimit
  namespace: prod-itex-servers
  context: SIDECAR_INBOUND
  workloadSelector:
    app: user-api
  portNumber: 80
  domain: user-api
  descriptorValue: user-api
  requestsPerUnit: 2000
  unit: SECOND
  statPrefix: user_api_global_ratelimit
```

执行：

```bash
ansible-playbook -i inventory.ini site.yml --tags istio-global-ratelimit
```

## 8. 如何禁用某条策略？

加：

```yaml
enabled: false
```

例如：

```yaml
- name: order-api-global-ratelimit
  enabled: false
  namespace: prod-itex-servers
  context: SIDECAR_INBOUND
  workloadSelector:
    app: order-api
  portNumber: 80
  domain: order-api
  descriptorValue: order-api
  requestsPerUnit: 1000
  unit: SECOND
```

重新执行 Ansible 后，不会渲染这条 EnvoyFilter 和 ratelimit descriptor。

## 9. 如何验证？

查看组件：

```bash
kubectl -n istio-ratelimit get pods,svc -o wide
```

查看 EnvoyFilter：

```bash
kubectl get envoyfilter -A | grep ratelimit
```

查看 ratelimit 日志：

```bash
kubectl -n istio-ratelimit logs deploy/ratelimit --tail=100
```

查看 Redis：

```bash
kubectl -n istio-ratelimit logs deploy/ratelimit-redis --tail=100
```

访问压测：

```bash
for i in $(seq 1 5000); do
  curl -k -s -o /dev/null -w "%{http_code}\n" https://decision.itexcloud.com
done
```

如果触发限流，会看到：

```text
429
```

## 10. 如何确认 Envoy 配置下发？

查 gateway pod：

```bash
kubectl -n istio-ingress-public get pods
```

查看 listener/filter：

```bash
istioctl proxy-config listener <gateway-pod> -n istio-ingress-public | grep ratelimit
```

查看 cluster：

```bash
istioctl proxy-config cluster <gateway-pod> -n istio-ingress-public | grep rate_limit_cluster
```

如果没有，通常是：

```text
workloadSelector label 不匹配
context 不对
portNumber 不对
EnvoyFilter 没有应用到正确 namespace
```

## 11. 当前模板的限制

当前模板是通用兜底限流：

```text
按 gateway / service 整体限流
```

它还没有做：

```text
按 IP 限流
按用户 ID 限流
按 Header 限流
按 API Key 限流
按路径限流
```

这些可以继续增强 EnvoyFilter 的 `rate_limits.actions`。

## 12. 按路径 / Header 限流怎么做？

后续可以扩展成：

```text
descriptor:
  generic_key + request_headers
```

例如：

```text
x-user-id
x-api-key
:path
:authority
x-forwarded-for
```

典型场景：

```text
/login 每 IP 每分钟 20 次
/order/create 每用户每秒 5 次
/api/* 每 API Key 每分钟 1000 次
```

这类策略建议单独做更细的模板，不要和当前基础版混太复杂。

## 13. 生产建议

当前 Redis 是单副本，适合测试和初期。

生产建议：

```text
外部 Redis / Redis Sentinel / Redis Cluster
ratelimit service 至少 2 副本
failure_mode_deny=false 起步
先对 gateway 做限流
再对核心服务做限流
```

### failure_mode_deny

当前默认：

```yaml
istio_global_ratelimit_failure_mode_deny: false
```

意思是：

```text
如果 ratelimit service 挂了，流量放行
```

这更适合初期，避免限流服务故障导致业务全挂。

如果改成：

```yaml
istio_global_ratelimit_failure_mode_deny: true
```

意思是：

```text
如果 ratelimit service 挂了，流量拒绝
```

安全性更高，但风险也更大。

## 14. 推荐上线顺序

```text
1. 先部署 ratelimit service + Redis
2. public gateway 开较大 QPS 兜底
3. internal gateway 开较小 QPS
4. 观察 429 和 ratelimit 日志
5. 再逐步给核心服务加全局限流
6. 最后再做按用户/IP/API Key/路径的细粒度限流
```

## 15. 和本地限流怎么搭配？

推荐：

```text
Gateway 本地限流：
  每个 gateway 副本 5000 QPS

Gateway 全局限流：
  所有 gateway 副本共享 3000 QPS

服务本地限流：
  每个 order-api Pod 200 QPS

服务全局限流：
  所有 order-api Pod 共享 1000 QPS
```

原则：

```text
全局限流做业务配额
本地限流做单点保护
```

'@ | Set-Content -Encoding UTF8 "roles/istio-global-ratelimit/docs/USAGE.md"

````

---

# 8. 重要提醒

这套是**基础全局限流**，先做：

```text
Gateway 整体全局限流
Service 整体全局限流
````

后面要做更高级的：

```text
按 IP
按用户 ID
按 API Key
按路径
按租户
```

建议再扩展第二版模板，不要一开始把 EnvoyFilter 写得太复杂。
