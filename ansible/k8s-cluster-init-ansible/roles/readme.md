# roles

该目录保存 Kubernetes 高可用集群和平台组件部署所需的 Ansible roles。每个 role 目录下都有独立 `readme.md`，说明该 role 的用途、关键变量、执行方式和验证命令。

## 基础集群 roles

- `system_update`: 系统更新和按需重启。
- `common`: 节点基础初始化。
- `containerd`: 安装和配置 containerd。
- `kube`: 安装 kubelet、kubeadm、kubectl。
- `kube-vip`: 部署控制面 VIP 静态 Pod。
- `kubeadm`: 初始化首个 master，并加入其他 master/worker。
- `cli-tools`: 安装 helm、cilium、hubble 等 CLI。
- `cni`: 安装 Cilium CNI。

## 存储和基础能力

- `local-path`: 安装 local-path-provisioner。
- `longhorn-prereq`: 安装 Longhorn 节点依赖。
- `longhorn`: 安装 Longhorn。
- `nfs-server`: 部署 NFS 服务。
- `dirs`: 初始化 NFS 目录。
- `metrics-server`: 安装 metrics-server。
- `cert-manager`: 安装 cert-manager。
- `sealed-secrets`: 安装 Sealed Secrets。

## 网关和服务治理

- `apisix`: 安装 APISIX 网关。
- `apisix-routes-internal`: 配置 APISIX 内网路由。
- `istio`: 安装 Istio。
- `istio-routes-internal`: 配置 Istio 内网路由。
- `istio-routes-public`: 配置 Istio 公网路由。
- `istio-traffic-policies`: 配置灰度、超时、重试和熔断。
- `istio-security-policies`: 配置 mTLS 等安全策略。
- `istio-rate-limit-policies`: 配置本地限流。
- `istio-global-ratelimit`: 配置全局限流。
- `istio-authz-policies`: 配置服务间授权策略。
- `kube-vip-loadbalance`: 部署 kube-vip LoadBalancer 能力。
- `lb`: 配置传统 Nginx/Keepalived 负载均衡。

## 可观测和安全

- `kube-prometheus-stack`: 安装 Prometheus/Alertmanager 等。
- `grafana`: 安装 Grafana。
- `loki`: 安装 Loki。
- `alloy`: 安装 Grafana Alloy。
- `tempo`: 安装 Tempo。
- `kiali`: 安装 Kiali。
- `kyverno`: 安装 Kyverno。
- `kyverno-policies`: 下发 Kyverno 基线策略。
- `network-policies`: 下发基础 NetworkPolicy。
- `trivy-operator`: 安装 Trivy Operator。
- `velero`: 安装 Velero 备份组件。

## 平台组件

- `argocd`: 安装 Argo CD。
- `rancher`: 安装 Rancher。
- `jumpserver`: 安装 JumpServer。
- `verdaccio`: 安装 Verdaccio npm registry。

## 使用方式

进入 Ansible 主目录：

```bash
cd ansible/k8s-cluster-init-ansible
```

按 tag 执行指定 role 或一组 role：

```bash
ansible-playbook -i inventory.ini site.yml --tags <tag>
```

具体 tag 和部署顺序请参考项目根目录 `readme.md`，每个 role 的细节请进入对应目录查看 `readme.md`。
