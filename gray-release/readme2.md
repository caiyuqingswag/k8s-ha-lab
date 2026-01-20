# 企业级 Kubernetes 灰度发布与安全基线终章大礼包

> 适用于：Istio + 多微服务 + 生产环境 + CKS 安全基线

---

## 1. 目录结构

```text
gray-release/
  canary/              # istios的流量分流
  gray-saas-v1/        # v1版本
  gray-saas-v2/        # v2版本 
  no-gray-saas/        # 单服务基础部署（不带灰度）
  service/             # 单独service部署（不带灰度）
```

---

## 2. 灰度发布 SOP（标准流程）

### Step 1：部署 v1（稳定版本）

```bash
kubectl apply -f gray-saas-v1/xxx-v1.yaml
```

### Step 2：部署 v2（新版本）

```bash
kubectl apply -f gray-saas-v2/xxx-v2.yaml
```

### Step 3：应用 Istio 分流（95/5）

```bash
kubectl apply -f canary/xxx-virtualservice.yaml
```

### Step 4：逐步放量

| 阶段 | v1  | v2   |
| -- | --- | ---- |
| 初始 | 95% | 5%   |
| 观察 | 80% | 20%  |
| 放量 | 50% | 50%  |
| 切换 | 0%  | 100% |

---

## 3. 回滚 SOP（1 分钟恢复）

### 方式一：流量回滚（推荐）

修改 VirtualService：

```yaml
weight: 100  # v1
weight: 0    # v2
```

### 方式二：下线 v2

```bash
kubectl delete deployment xxx-v2 -n saas
```

---

## 4. 发布 Checklist（上线前必看）

### 资源检查

* [ ] CPU request / limit 合理
* [ ] Memory request / limit 合理
* [ ] readinessProbe 正确
* [ ] livenessProbe 正确
* [ ] startupProbe（启动慢的服务）

### 安全基线

* [ ] 非 root 运行
* [ ] allowPrivilegeEscalation=false
* [ ] drop ALL capabilities
* [ ] seccompProfile=RuntimeDefault
* [ ] 无 hostPath
* [ ] 无 privileged

### Istio

* [ ] DestinationRule 已创建
* [ ] VirtualService 权重正确
* [ ] 无 0/100 误操作

---

## 5. CKS 安全基线说明

### Pod 级别

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 10001
  runAsGroup: 10001
  fsGroup: 10001
  seccompProfile:
    type: RuntimeDefault
```

### Container 级别

```yaml
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
```

### 禁止项（生产环境）

| 配置               | 原因        |
| ---------------- | --------- |
| privileged: true | 直接逃逸风险    |
| hostNetwork      | 容器可监听宿主网络 |
| hostPath         | 可读写宿主文件   |
| runAsRoot        | 权限过大      |

---

## 6. Istio 使用规范

### 必须使用

* VirtualService
* DestinationRule
* Subset = version

### 禁止行为

* 直接改 Service selector
* 直接删除 v1
* 一次性 0/100

---

## 7. 生产发布黄金法则

| 原则                  | 说明                |
| ------------------- | ----------------- |
| 不删旧版本               | 灰度必须保留回滚能力        |
| 只动流量                | 发布 = 改权重          |
| 探针先于流量              | readiness 决定是否接流量 |
| 慢启动必须有 startupProbe |                   |

---

## 8. 常见事故规避

| 错误                | 后果             |
| ----------------- | -------------- |
| 没有 readinessProbe | 流量打到未启动完成的 Pod |
| 直接删 v1            | 无法回滚           |
| 0/100 直切          | 高风险            |
| NodePort 暴露内部服务   | 安全事故           |

---

## 9. 体系成熟度

| 能力    | 状态 |
| ----- | -- |
| 灰度发布  | ✅  |
| 流量治理  | ✅  |
| 回滚能力  | ✅  |
| 安全基线  | ✅  |
| 生产规范  | ✅  |
| 企业级标准 | ✅  |

---