# kyverno-policies

该 role 用于下发 Kyverno 基线策略，默认以 Audit 模式进行检查，适合作为上线前的安全观察和逐步治理入口。

## 主要工作

- 在首个 master 上创建工作目录。
- 根据 `kyverno_policy_target_namespaces` 渲染 `baseline-policies.yaml`。
- 等待 kube-apiserver 可访问。
- 确保目标 namespace 存在。
- 应用 Kyverno ClusterPolicy/Policy 清单。

## 关键变量

- `kyverno_policies_work_dir`: 清单生成目录。
- `kyverno_policy_validation_action`: 策略动作，默认 `Audit`。
- `kyverno_policy_excluded_namespaces`: 排除的平台系统命名空间列表。
- `kyverno_restrict_registries_enabled`: 是否启用镜像仓库白名单策略。
- `kyverno_allowed_registries`: 允许使用的镜像仓库列表。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags kyverno-policies
```

## 验证

```bash
kubectl get clusterpolicy,policy -A
kubectl get policyreport -A
```
