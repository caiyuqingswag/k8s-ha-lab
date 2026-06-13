# k8s-ha-lab

`k8s-ha-lab` 是一套面向 Ubuntu 24.04 的 Kubernetes 高可用集群部署与业务交付实验/生产化模板。项目以 Ansible 为主线完成集群初始化，并配套提供网关、存储、可观测、安全、备份、GitOps 和业务/中间件 Kubernetes 清单。

当前分支重点组合：

- Ubuntu 24.04
- Kubernetes 1.36.1
- containerd
- kubeadm
- kube-vip 控制面 VIP
- Cilium CNI，启用 kube-proxy replacement
- APISIX / Istio 入口与治理能力
- Longhorn / local-path 存储
- Prometheus、Grafana、Loki、Alloy、Tempo 可观测体系
- Argo CD、Rancher、Kyverno、Trivy Operator、Velero、Sealed Secrets 等平台组件

## 目录结构

```text
k8s-ha-lab/
├── ansible/
│   └── k8s-cluster-init-ansible/
│       ├── inventory.ini        # 集群节点、VIP、Ansible 连接信息
│       ├── group_vars/          # 全局变量和敏感变量
│       ├── site.yml             # 集群与平台组件主编排
│       └── roles/               # 各部署模块，每个 role 均有 readme.md
├── argo_cd_deployment/          # 业务应用 GitOps/Kubernetes 清单
├── middleware/                  # 中间件部署清单与存储方案说明
├── LICENSE
└── readme.md
```

## 集群拓扑

默认 inventory 是 3 个控制面节点、3 个 worker 节点：

```text
master1  192.168.0.51
master2  192.168.0.52
master3  192.168.0.53
node1    192.168.0.54
node2    192.168.0.55
node3    192.168.0.56
```

控制面 VIP：

```text
prod-hz-01-api -> 192.168.0.50:6443
```

默认 Ansible 用户为 `ubuntu`，并通过 sudo 提权。部署前请按真实服务器信息修改：

```text
ansible/k8s-cluster-init-ansible/inventory.ini
ansible/k8s-cluster-init-ansible/group_vars/all.yml
ansible/k8s-cluster-init-ansible/group_vars/vault.yml
```

## 部署前准备

控制机需要具备：

- Ansible
- SSH 到所有节点的免密或可认证访问
- sudo 权限
- 节点网络互通
- 节点 hostname、VIP、DNS 或 `/etc/hosts` 规划完成

所有节点建议提前确认：

```bash
lsb_release -a
ip addr
timedatectl
sudo -v
```

如果使用 `prod-hz-01-api` 作为控制面入口，需要保证部署机和所有节点能解析到 `192.168.0.50`。

## 快速开始

进入 Ansible 目录：

```bash
cd ansible/k8s-cluster-init-ansible
```

检查 inventory 连通性：

```bash
ansible -i inventory.ini all -m ping
```

建议按阶段执行，而不是第一次就直接全量跑 `site.yml`。

## 推荐部署顺序

### 1. 系统初始化

```bash
ansible-playbook -i inventory.ini site.yml --tags update
ansible-playbook -i inventory.ini site.yml --tags common
```

### 2. 容器运行时和 Kubernetes 组件

```bash
ansible-playbook -i inventory.ini site.yml --tags containerd
ansible-playbook -i inventory.ini site.yml --tags kube
```

### 3. 初始化高可用控制面

```bash
ansible-playbook -i inventory.ini site.yml --tags init
ansible-playbook -i inventory.ini site.yml --tags cli
ansible-playbook -i inventory.ini site.yml --tags cilium
ansible-playbook -i inventory.ini site.yml --tags join_masters
ansible-playbook -i inventory.ini site.yml --tags join_workers
```

验证集群：

```bash
kubectl get nodes -o wide
kubectl -n kube-system get pods -o wide
cilium status
```

### 4. 存储和基础平台组件

```bash
ansible-playbook -i inventory.ini site.yml --tags local-path
ansible-playbook -i inventory.ini site.yml --tags longhorn-prereq
ansible-playbook -i inventory.ini site.yml --tags longhorn
ansible-playbook -i inventory.ini site.yml --tags metrics
ansible-playbook -i inventory.ini site.yml --tags cert
```

`group_vars/all.yml` 中的 `global_storage_class` 控制多个平台组件默认使用的存储类。测试环境可用 `local-path`，生产环境建议使用 `longhorn` 或其他可靠存储。

### 5. 网关和服务治理

APISIX 双入口：

```bash
ansible-playbook -i inventory.ini site.yml --tags apisix-public
ansible-playbook -i inventory.ini site.yml --tags apisix-internal
ansible-playbook -i inventory.ini site.yml --tags apisix-routes-internal
```

Istio 服务网格：

```bash
ansible-playbook -i inventory.ini site.yml --tags istio
ansible-playbook -i inventory.ini site.yml --tags istio-routes-internal
ansible-playbook -i inventory.ini site.yml --tags istio-routes-public
ansible-playbook -i inventory.ini site.yml --tags istio-traffic-policies
ansible-playbook -i inventory.ini site.yml --tags istio-security-policies
ansible-playbook -i inventory.ini site.yml --tags istio-rate-limit-policies
ansible-playbook -i inventory.ini site.yml --tags istio-global-ratelimit
ansible-playbook -i inventory.ini site.yml --tags istio-authz-policies
```

### 6. 可观测、安全和运维组件

```bash
ansible-playbook -i inventory.ini site.yml --tags prometheus
ansible-playbook -i inventory.ini site.yml --tags grafana
ansible-playbook -i inventory.ini site.yml --tags loki
ansible-playbook -i inventory.ini site.yml --tags alloy
ansible-playbook -i inventory.ini site.yml --tags tempo
ansible-playbook -i inventory.ini site.yml --tags kiali
ansible-playbook -i inventory.ini site.yml --tags kyverno
ansible-playbook -i inventory.ini site.yml --tags kyverno-policies
ansible-playbook -i inventory.ini site.yml --tags trivy-operator
ansible-playbook -i inventory.ini site.yml --tags velero
ansible-playbook -i inventory.ini site.yml --tags sealed-secrets
```

### 7. 管理和业务辅助组件

```bash
ansible-playbook -i inventory.ini site.yml --tags argocd
ansible-playbook -i inventory.ini site.yml --tags rancher
ansible-playbook -i inventory.ini site.yml --tags jumpserver
ansible-playbook -i inventory.ini site.yml --tags verdaccio
```

如需部署 NFS 和初始化目录：

```bash
ansible-playbook -i inventory.ini site.yml --tags nfs
ansible-playbook -i inventory.ini site.yml --tags dir
```

## 常用 tag 对照

| tag | 作用 |
| --- | --- |
| `update` | 系统更新和内核升级 |
| `common` | 节点基础初始化 |
| `containerd` | 安装 containerd 和 crictl |
| `kube` | 安装 kubelet、kubeadm、kubectl |
| `init` | 首个 master 上部署 kube-vip 并执行 kubeadm init |
| `cli` | 安装 helm、cilium、hubble 等 CLI |
| `cilium` | 安装 Cilium CNI |
| `join_masters` | 其他 master 加入集群 |
| `join_workers` | worker 加入集群 |
| `local-path` | 安装 local-path-provisioner |
| `longhorn-prereq` | 安装 Longhorn 节点前置依赖 |
| `longhorn` | 安装 Longhorn |
| `metrics` | 安装 metrics-server |
| `cert` | 安装 cert-manager |
| `apisix-public` | 安装公网 APISIX 网关 |
| `apisix-internal` | 安装内网 APISIX 网关 |
| `istio` | 安装 Istio base、istiod、gateway |
| `prometheus` | 安装 kube-prometheus-stack |
| `grafana` | 安装 Grafana |
| `loki` | 安装 Loki |
| `alloy` | 安装 Grafana Alloy |
| `tempo` | 安装 Tempo |
| `argocd` | 安装 Argo CD |
| `rancher` | 安装 Rancher |
| `kyverno` | 安装 Kyverno |
| `trivy-operator` | 安装 Trivy Operator |
| `velero` | 安装 Velero |
| `sealed-secrets` | 安装 Sealed Secrets |
| `jumpserver` | 安装 JumpServer |
| `verdaccio` | 安装 Verdaccio npm registry |
| `nfs` | 部署 NFS server |
| `dir` | 初始化 NFS 目录 |

每个 role 的详细变量、执行内容和验证命令见：

```text
ansible/k8s-cluster-init-ansible/roles/<role-name>/readme.md
```

## 业务应用清单

`argo_cd_deployment/` 下保存业务应用的 Kubernetes/Argo CD 部署清单，按业务线划分：

- `paas/`: PaaS 平台相关服务。
- `saas/`: SaaS/业务系统相关服务。

建议流程：

```bash
kubectl apply -f argo_cd_deployment/<目录>/<应用>.yaml
```

如果已经接入 Argo CD，也可以把这些清单作为 GitOps 源，由 Argo CD 统一同步。

## 中间件清单

`middleware/` 下保存中间件部署清单和存储方案说明：

- `monolithic-architecture/`: 偏单体或小规模环境的中间件清单，包含 MySQL、Redis、RabbitMQ、MinIO、InfluxDB、MongoDB 等。
- `distributed-architecture/`: 面向分布式/高可用存储方案的说明。

中间件部署前请先确认 StorageClass、PV/PVC、namespace、账号密码和 NodePort 等配置是否符合当前环境。

## 重要注意事项

- `group_vars/vault.yml` 和各 role defaults 中可能包含示例密码，生产环境请使用 Ansible Vault 或外部密钥系统管理。
- APISIX、Istio、Rancher、JumpServer、Verdaccio 等入口默认多为 `ClusterIP` 或 NodePort，需要结合内网/公网 CLB、DNS 和证书规划。
- `Velero` 默认配置需要外部 S3/MinIO 参数，部署前必须替换 bucket、endpoint、access key 和 secret key。
- `Kyverno` 基线策略默认建议先用 Audit，观察无误后再逐步切到 Enforce。
- `kube-vip-loadbalance` 在 `site.yml` 中默认注释，如需 Service LoadBalancer 能力，需要先确认地址池和网络规划后再启用。
- 部署顺序很重要：CNI 未完成前，后续 Pod 组件大概率无法正常 Ready。

## 常用验证命令

```bash
kubectl get nodes -o wide
kubectl get storageclass
kubectl get pods -A
kubectl get svc -A
kubectl get ingress -A
kubectl get gateway,virtualservice -A
kubectl top nodes
helm list -A
```

## 排障入口

```bash
kubectl describe pod -n <namespace> <pod>
kubectl logs -n <namespace> <pod> --tail=200
kubectl get events -A --sort-by=.lastTimestamp
journalctl -u kubelet -n 200 --no-pager
journalctl -u containerd -n 200 --no-pager
```

平台组件排障时，优先查看对应 role 的 `readme.md`、渲染到 `/etc/kubernetes/<component>/` 下的 values/manifest，以及目标 namespace 中的 Pod 事件。
