# Kubernetes Pod Security & ServiceAccount 安全基线说明

本文档用于说明当前集群中 **业务命名空间（saas）** 与 **基础组件命名空间（sit-basic / dev-basic）** 的 Pod Security（PSA）与 ServiceAccount 安全加固策略，以及对应的操作命令。

---

## 一、Pod Security Admission（PSA）命名空间分级策略

### 1. `saas` 命名空间（业务服务）

**策略级别：`restricted`（最严格）**

业务 Pod 是最容易被外部攻击触达的对象（HTTP API、外部请求等），因此采用 **restricted** 级别，强制限制高风险 Pod 行为（如特权容器、提权、危险 capability 等）。

#### 执行命令

```bash
kubectl label namespace saas \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted \
  --overwrite
```

#### 效果说明

* `enforce=restricted`：不符合 restricted 的 Pod **直接拒绝创建**
* `audit=restricted`：记录不合规行为到审计日志
* `warn=restricted`：kubectl 操作时给出告警提示
* 只对 **新建 / 更新 Pod** 生效，不影响已运行 Pod

---

### 2. `sit-basic` 命名空间（基础组件）

**策略级别：`baseline`（兼顾安全与兼容性）**

基础组件（如 MySQL / Redis / MongoDB / MinIO / RabbitMQ 等）通常依赖官方镜像，历史包袱较多，因此采用 **baseline** 级别，拦截明显高危配置，但不强制所有 CKS 硬化项。

#### 执行命令

```bash
kubectl label ns sit-basic \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/audit=baseline \
  pod-security.kubernetes.io/warn=baseline \
  --overwrite
```

#### 效果说明

* 禁止特权容器、hostNetwork、hostPID、hostPath 等高危配置
* 允许组件以较宽松但仍安全的方式运行
* 适合作为中间件/基础设施命名空间的默认策略

---

## 二、ServiceAccount Token 安全加固

### 背景说明

Kubernetes 默认会为 Pod 自动挂载 ServiceAccount token。
如果业务 Pod 被入侵，攻击者可能通过该 token 访问 Kubernetes API，造成**横向移动或集群级风险**。

因此，本集群采用 **“默认不挂载 token，按需开启”** 的策略。

---

### 1. 关闭 `dev-basic` 命名空间默认 ServiceAccount 的 token 挂载

```bash
kubectl patch sa default -n dev-basic -p '{"automountServiceAccountToken": false}'
```

### 2. 关闭 `saas` 命名空间默认 ServiceAccount 的 token 挂载

```bash
kubectl patch sa default -n saas -p '{"automountServiceAccountToken": false}'
```

#### 效果说明

* 该命名空间中 **未显式声明 ServiceAccount 的 Pod**，将不会自动挂载 token
* 防止未来新建 Pod 因遗漏配置而意外挂载 token
* 对现有 Pod **不会造成重启或影响**

---

## 三、验证方式（可选）

### 1. 查看命名空间 PSA 标签

```bash
kubectl get namespace saas sit-basic --show-labels
```

### 2. 查看 Pod 是否挂载 ServiceAccount token

```bash
kubectl get pod -A -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{" "}{.spec.automountServiceAccountToken}{"\n"}{end}'
```

正常情况下：

* 业务 / 组件命名空间 Pod：`false`
* `kube-system` 命名空间 Pod：`true`（正常且必须）

---

## 四、整体安全策略总结

| 区域            | 策略                               |
| ------------- | -------------------------------- |
| saas（业务）      | PSA `restricted` + 禁止默认 SA token |
| sit-basic（组件） | PSA `baseline`                   |
| dev-basic     | 禁止默认 SA token                    |
| kube-system   | 保持默认（不干预）                        |

该策略在 **云厂商自建 Kubernetes + VPC / 安全组隔离** 场景下，能够有效防止：

* 容器提权
* Kubernetes API 滥用
* Pod 被攻陷后的横向扩散
* 高危 Pod 配置误入生产环境

---