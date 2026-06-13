# network-policies

该 role 为目标命名空间下发基础 NetworkPolicy，提供默认拒绝入口流量、允许同命名空间访问、允许网关访问等基线网络隔离能力。

## 主要工作

- 在首个 master 上创建工作目录。
- 根据 `network_policy_target_namespaces` 渲染 `baseline-network-policies.yaml`。
- 等待 kube-apiserver 可访问。
- 确保目标 namespace 存在。
- 应用 NetworkPolicy 清单。

## 关键变量

- `network_policies_work_dir`: 清单生成目录。
- `network_policy_target_namespaces`: 要应用基线策略的 namespace 列表。
- 模板中包含 `default-deny-ingress`、`allow-same-namespace`、`allow-from-apisix-gateways` 等策略。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags network-policies
```

## 验证

```bash
kubectl get networkpolicy -A
```
