先只做 **mTLS 加密策略**，不要一上来加复杂授权，避免业务突然互相访问失败。

Istio 加密主要靠：

```text
PeerAuthentication
```

推荐上线顺序：

```text
PERMISSIVE 观察期 -> STRICT 强制加密
```

---

## 执行
先用默认 `PERMISSIVE`：
```bash
ansible-playbook -i inventory.ini site.yml --tags istio-security-policies
```
检查：

```bash
kubectl get peerauthentication -A
kubectl get destinationrule -A | grep mtls
```

---

## PERMISSIVE 和 STRICT 是什么意思？

### PERMISSIVE

```yaml
mode: PERMISSIVE
```

意思是：

```text
接受 mTLS 流量
也接受明文流量
```

适合刚开始接入 Istio 的阶段。

比如：

```text
有 sidecar 的服务 -> 有 sidecar 的服务：mTLS
没 sidecar 的服务 -> 有 sidecar 的服务：明文也允许
```

优点是不容易把业务打挂。

---

### STRICT

```yaml
mode: STRICT
```

意思是：

```text
只接受 mTLS 流量
不接受明文流量
```

适合所有调用方都已经注入 sidecar 后。

比如 `prod-itex-servers` 开了 STRICT 后：

```text
有 sidecar 的服务 -> prod-itex-servers 服务：允许
没 sidecar 的服务 -> prod-itex-servers 服务：拒绝
```

---

## 上线建议

你现在先保持：

```yaml
istio_mtls_mode: "PERMISSIVE"
```

观察一段时间后，确认这些 namespace 里的业务 Pod 都是 `2/2`：

```bash
for ns in \
prod-itex-components \
prod-itex-servers \
prod-paas-components \
prod-srm-components \
stable-itex-components \
stable-itex-servers
do
  echo "===== $ns ====="
  kubectl -n $ns get pods
done
```

再改成：

```yaml
istio_mtls_mode: "STRICT"
```

然后重跑：

```bash
ansible-playbook -i inventory.ini site.yml --tags istio-security-policies
```

---

## 验证 mTLS 是否生效

查看某个 Pod 的 TLS 配置：

```bash
istioctl authn tls-check <pod-name>.<namespace>
```

例如：

```bash
istioctl authn tls-check order-api-xxxxx.prod-itex-servers
```

也可以看 proxy 配置：

```bash
istioctl proxy-config clusters <pod-name> -n prod-itex-servers | grep -i tls
```

---

## 重要注意

不要一开始打开：

```yaml
istio_enable_mesh_wide_mtls: true
istio_mesh_mtls_mode: "STRICT"
```

这个是全 mesh 强制加密，容易影响平台组件或没注入 sidecar 的服务。

更稳的方式是：

```text
第一阶段：业务 namespace PERMISSIVE
第二阶段：单个 namespace STRICT
第三阶段：所有业务 namespace STRICT
第四阶段：再考虑 mesh-wide STRICT
```

这套 `istio-security-policies` 现在只负责 **mTLS 加密**。下一步如果要做“服务 A 只能访问服务 B”这种权限控制，再加 `AuthorizationPolicy`