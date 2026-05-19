执行：
```bash
ansible-playbook -i inventory.ini site.yml --tags istio-authz-policies
```

检查：

```bash
kubectl get authorizationpolicy -A
```

---
### 例子：只允许 order-api 访问 user-api

配置：

```yaml
- name: allow-user-api-from-order-api
  namespace: prod-itex-servers
  selectorLabels:
    app: user-api
  allowedFromPrincipals:
    - cluster.local/ns/prod-itex-servers/sa/order-api
```

意思是：

```text
目标：prod-itex-servers namespace 里 app=user-api 的 Pod
允许来源：prod-itex-servers/order-api 这个 ServiceAccount
其他来源：拒绝
```

前提是 `order-api` 的 Deployment 要写：

```yaml
spec:
  template:
    spec:
      serviceAccountName: order-api
```

并且有对应 ServiceAccount：

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: order-api
  namespace: prod-itex-servers
```

---

## 上线建议

先不要打开：

```yaml
istio_authz_enable_default_deny: true
```

先保持：

```yaml
istio_authz_enable_default_deny: false
```

因为只要某个服务有 `AuthorizationPolicy` 的 `ALLOW` 策略，Istio 对该服务就会进入“只允许匹配规则”的模式。

也就是说：

```text
没有 AuthorizationPolicy 的服务：
  默认允许

有 AuthorizationPolicy ALLOW 的服务：
  只允许规则里写的来源
```

等把调用关系整理清楚后，再开启 namespace 级：

```yaml
istio_authz_enable_default_deny: true
```
