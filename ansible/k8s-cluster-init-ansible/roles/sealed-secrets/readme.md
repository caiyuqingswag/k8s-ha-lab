# 使用方法

## 1. 创建普通 Secret 文件，不要提交 Git

例如创建 Grafana 密码：

```bash
kubectl -n monitoring create secret generic grafana-admin-secret \
  --from-literal=admin-user=admin \
  --from-literal=admin-password='YourStrongPassword' \
  --dry-run=client \
  -o yaml > grafana-admin-secret.yaml
```

这个 `grafana-admin-secret.yaml` 是明文，**不要提交 Git**。

---

## 2. 转成 SealedSecret

```bash
kubeseal \
  --controller-name=sealed-secrets-controller \
  --controller-namespace=kube-system \
  --format yaml \
  < grafana-admin-secret.yaml \
  > grafana-admin-sealedsecret.yaml
```

这个 `grafana-admin-sealedsecret.yaml` 可以提交 Git。

---

## 3. 应用 SealedSecret

```bash
kubectl apply -f grafana-admin-sealedsecret.yaml
```

Sealed Secrets controller 会自动生成真正的 Kubernetes Secret：

```bash
kubectl -n monitoring get secret grafana-admin-secret
```

---

## 4. SealedSecret 示例

生成后的大概长这样：

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: grafana-admin-secret
  namespace: monitoring
spec:
  encryptedData:
    admin-password: AgBxxxxxx
    admin-user: AgBxxxxxx
  template:
    metadata:
      name: grafana-admin-secret
      namespace: monitoring
    type: Opaque
```

提交到 Git 的是这个。

---

## 5. 默认加密作用域

默认是 **strict scope**：

```text
Secret 名字必须一致
namespace 必须一致
```

也就是说这个 SealedSecret 只能解密成：

```text
monitoring/grafana-admin-secret
```

不能拿去别的 namespace 用。这个更安全。

```bash
kubeseal --scope namespace-wide ...
```

如果想跨 namespace 复用，可以用：

```bash
kubeseal --scope cluster-wide ...
```

但生产建议默认 strict。

---

## 6. GitOps 推荐目录

后面你的 GitOps 仓库可以这样放：

```text
clusters/
  prod-hz-01/
    platform/
      grafana/
        grafana-admin-sealedsecret.yaml
      apisix/
        apisix-admin-sealedsecret.yaml
      velero/
        minio-credentials-sealedsecret.yaml
```

Argo CD 同步后，controller 自动解密生成 Secret。

---

## 7. 备份 Sealed Secrets 私钥，非常重要

Sealed Secrets 的私钥在集群里，必须备份。否则集群重建后，Git 里的 SealedSecret 可能无法解密。

查看密钥：

```bash
kubectl -n kube-system get secret | grep sealed-secrets-key
```

备份：

```bash
kubectl -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key \
  -o yaml > sealed-secrets-master-key-backup.yaml
```

这个文件是**最高敏感级别**，不要提交普通 Git。建议放到：

```text
离线加密备份
密码管理器
MinIO 私有 bucket
单独备份机
```

恢复时：

```bash
kubectl apply -f sealed-secrets-master-key-backup.yaml
kubectl -n kube-system rollout restart deploy/sealed-secrets-controller
```

---