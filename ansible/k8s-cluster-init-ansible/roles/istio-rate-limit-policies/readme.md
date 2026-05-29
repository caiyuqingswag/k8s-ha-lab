这个 role 先做 **本地限流 Local Rate Limit**，不依赖 Redis，不依赖额外限流服务。

它适合先解决：

```text
单服务限流
入口网关兜底限流
防止某个服务被瞬时流量打爆
```

后面如果要做“全局限流”，比如多副本共享 QPS、按用户 ID/IP/API Key 统一限流，再单独加：

```text
roles/istio-global-ratelimit
```

---

## 什么时候用 Local Rate Limit？

适合：

* 简单服务限流
* 防止单个 Pod 被打爆
* Gateway 入口兜底保护
* 不想引入 Redis / ratelimit service 的场景
* 初期快速落地

不适合：

* 多副本全局统一 QPS
* 按用户 ID 限流
* 按 API Key 限流
* 按 IP 精准限流
* 多集群统一限流

这些需要后续使用 **Global Rate Limit**。

##  核心配置在哪里？

文件：

```text
roles/istio-rate-limit-policies/defaults/main.yml
```

核心变量：

```yaml
istio_local_rate_limit_policies:
  - name: decision-flow-web-local-ratelimit
    namespace: prod-paas-components
    context: SIDECAR_INBOUND
    workloadSelector:
      app: decision-flow-web
    portNumber: 80
    maxTokens: 100
    tokensPerFill: 100
    fillInterval: 1s
```

## 5. 字段解释

### name

生成的 EnvoyFilter 名称。

```yaml
name: decision-flow-web-local-ratelimit
```

### namespace

EnvoyFilter 所在 namespace。

如果限业务服务，一般写业务服务所在 namespace：

```yaml
namespace: prod-paas-components
```

如果限 gateway，写 gateway 所在 namespace：

```yaml
namespace: istio-ingress-public
```

### context

限流生效位置。

```yaml
context: SIDECAR_INBOUND
```

表示限制进入业务 Pod sidecar 的流量。

```yaml
context: GATEWAY
```

表示限制进入 Istio Gateway 的流量。

### workloadSelector

选择要生效的 Pod。

例如：

```yaml
workloadSelector:
  app: decision-flow-web
```

要求目标 Pod 有这个 label：

```yaml
labels:
  app: decision-flow-web
```

如果 label 不匹配，限流不会生效。

### portNumber

目标端口。

业务服务一般是：

```yaml
portNumber: 80
```

Gateway HTTP 入口也是：

```yaml
portNumber: 80
```

### maxTokens / tokensPerFill / fillInterval

这是令牌桶配置。

```yaml
maxTokens: 100
tokensPerFill: 100
fillInterval: 1s
```

含义：

```text
桶最大容量 100 个 token
每 1 秒补充 100 个 token
大约等于每秒 100 个请求
```

如果设置：

```yaml
maxTokens: 500
tokensPerFill: 100
fillInterval: 1s
```

含义：

```text
允许瞬间突发最多 500 个请求
之后稳定速率约 100 QPS
```

### enabledPercent

是否启用限流过滤器。

```yaml
enabledPercent: 100
```

100 表示全部请求进入限流逻辑。

### enforcedPercent

是否真正强制拦截。

```yaml
enforcedPercent: 100
```

100 表示超过限制后直接返回 429。

如果想先观察，不真正拦截，可以设置：

```yaml
enabledPercent: 100
enforcedPercent: 0
```

### statusCodeName

超过限制时返回的状态码。

```yaml
statusCodeName: TooManyRequests
```

对应 HTTP 429。

### responseHeaders

限流响应时额外返回的 header。

```yaml
responseHeaders:
  - key: x-local-rate-limit
    value: "decision-flow-web"
```

限流触发时，响应里会带：

```text
x-local-rate-limit: decision-flow-web
```

方便排查。

## 示例：给业务服务限流

```yaml
- name: order-api-local-ratelimit
  namespace: prod-itex-servers
  context: SIDECAR_INBOUND
  workloadSelector:
    app: order-api
  portNumber: 80
  statPrefix: order_api_local_rate_limit
  maxTokens: 200
  tokensPerFill: 200
  fillInterval: 1s
  enabledPercent: 100
  enforcedPercent: 100
  statusCodeName: TooManyRequests
```

含义：

```text
每个 order-api Pod 每秒最多 200 个请求
超过后返回 429
```

如果 order-api 有 5 个 Pod，总体约等于：

```text
5 * 200 = 1000 QPS
```

## 示例：给 public gateway 限流

```yaml
- name: public-gateway-local-ratelimit
  namespace: istio-ingress-public
  context: GATEWAY
  workloadSelector:
    istio: ingressgateway-public
  portNumber: 80
  maxTokens: 1000
  tokensPerFill: 1000
  fillInterval: 1s
```

含义：

```text
每个 public gateway Pod 每秒最多 1000 请求
```

注意：这是整个 gateway 的兜底限流，不区分域名。

如果 public gateway 上有多个域名：

```text
api.itexcloud.com
order.itexcloud.com
user.itexcloud.com
```

它们会共享这个 gateway 限流桶。

## 应用配置

执行：

```bash
ansible-playbook -i inventory.ini site.yml --tags istio-rate-limit-policies
```

查看：

```bash
kubectl get envoyfilter -A
```

查看某个策略：

```bash
kubectl -n prod-itex-servers get envoyfilter order-api-local-ratelimit -o yaml
```

## 如何验证是否生效？

### 查看 Pod 是否有 sidecar

```bash
kubectl -n prod-itex-servers get pods
```

业务 Pod 应该是：

```text
READY 2/2
```

### 压测访问

可以用 curl 快速循环测试：

```bash
for i in $(seq 1 300); do
  curl -s -o /dev/null -w "%{http_code}\n" http://order.itexcloud.com
done
```

如果触发限流，会看到：

```text
429
```

如果你通过 CLB HTTPS 访问：

```bash
for i in $(seq 1 300); do
  curl -k -s -o /dev/null -w "%{http_code}\n" https://order.itexcloud.com
done
```

### 看响应头

```bash
curl -I https://order.itexcloud.com
```

触发限流时可能看到：

```text
x-local-rate-limit: order-api
```

## 如何只观察不拦截？

把策略改成：

```yaml
enabledPercent: 100
enforcedPercent: 0
```

意思是：

```text
启用限流逻辑
但是不真正返回 429
```

适合上线前观察。

## Local Rate Limit 的限制

Local Rate Limit 是每个 Envoy 独立计数，所以它不是全局统一 QPS。

例如：

```text
user-api 有 10 个 Pod
每个 Pod 限 300 QPS
整体大约是 3000 QPS
```

如果你想整个 user-api 不管多少 Pod 都固定 300 QPS，就需要 Global Rate Limit。

## Global Rate Limit 后续怎么做？

全局限流一般需要：

```text
Envoy Gateway / Istio EnvoyFilter
  -> ratelimit service
  -> Redis
```

它可以支持：

* 全局 QPS
* 按 IP 限流
* 按用户 ID 限流
* 按 API Key 限流
* 按路径限流
* 多 gateway 副本共享限流状态

后续可以单独做：

```text
roles/istio-global-ratelimit
```

## 上线顺序

建议：

```text
1. 先给 gateway 加大额度兜底限流
2. 再给核心服务加服务级限流
3. 初期 enforcedPercent 设置为 0 或较小比例
4. 观察日志和业务错误率
5. 再把 enforcedPercent 调整到 100
6. 最后再上全局限流
```

## 推荐角色划分

```text
roles/istio-traffic-policies
  灰度 / 超时 / 重试 / 熔断

roles/istio-security-policies
  mTLS 加密

roles/istio-authz-policies
  服务间授权

roles/istio-rate-limit-policies
  本地限流

roles/istio-global-ratelimit
  全局限流，后续再加

````
---

# 执行

```bash
ansible-playbook -i inventory.ini site.yml --tags istio-rate-limit-policies
```

检查：

```bash
kubectl get envoyfilter -A
```

查看渲染结果：

```bash
cat /etc/kubernetes/istio-rate-limit-policies/local-ratelimit-envoyfilters.yaml
```

---

如果要：

```text
整个 order-api 不管多少 Pod，总共只能 200 QPS
```

那就是下一步的 **Global Rate Limit + Redis**。