下面是在**不改变你技术含义**的前提下，对文档进行的一次 **工程化、规范化、可直接放到 README 的改写版本**。整体风格更偏向「开源项目 / 企业内部基线项目说明」，同时把**两个分支的定位和执行方式**讲清楚。

---

# Kubernetes HA Cluster Initialization with Ansible

## 项目简介

本项目基于 **Ansible** 实现 Kubernetes **高可用（HA）集群** 的初始化与基础环境自动化部署，适用于 **生产级**、**批量化**、**可重复执行** 的集群交付场景。

项目以 **Rockey Linux 10.1** 为基础系统，通过角色化（Role-based）的 Ansible Playbook，完整覆盖从 **操作系统初始化 → 容器运行时 → Kubernetes 组件 → HA 架构 → 网络插件 → 节点自动加入** 的全过程，替代传统零散、不可复用的 Shell 脚本方式。

该方案在 **几十到上百台节点规模** 下，能够显著降低人为操作风险，提高交付一致性与稳定性。

---

## 项目目标

* 实现 Kubernetes 集群 **全流程自动化初始化**
* 自动完成系统调优、运行时、Kubernetes 核心组件部署
* 支持多种 **高可用控制平面架构**
* 适配 **云厂商自建** 与 **私有环境自建** 两类场景
* 使用加速镜像源，加速组件与镜像拉取
* 所有关键配置 **可追溯、可验证**
* 支持 **幂等执行**，可安全重复运行
* 显著缩短大规模集群初始化时间

---

## 分支说明（重点）

当前项目维护 **两个稳定分支**，（截至2026/02/02，后续会新增ubuntu24.04操作系统来部署）分别针对不同部署环境设计：

### 1️⃣ 云厂商自建 Kubernetes（推荐云环境）

**分支：**

```
remotes/origin/Rockey10.1_ansible_k8s1.35.0_calico_nginx+keepalived
```

**特点：**

* 控制平面高可用：`nginx + keepalived` （需要云厂商申请高可用虚拟ip来作为vip）
* CNI：`Calico`
* 架构成熟、兼容性好
* 更贴近云厂商网络与 LB 使用习惯
* 适合：
    * 公有云 / 私有云也可以,看具体需求
    * 云厂商自建 k8s
    * 对网络策略要求明确的环境

**执行方式：**

```bash
# 系统更新（可单独执行）
ansible-playbook -i inventory.ini site.yml --tags update -vv

# 集群完整初始化
ansible-playbook -i inventory.ini site.yml \
  --tags common,lb,containerd,kube,init,cli,join_masters,join_workers,nfs,dir \
  -vv
```

---

### 2️⃣ 私有环境 / 裸金属 Kubernetes（推荐内网）

**分支：**

```
remotes/origin/Rockey10.1_ansible_k8s1.35.0_cilium_kube-vip
```

**特点：**

* 控制平面高可用：`kube-vip` 
  * 默认：基于 ARP 的二层 VIP 地址通告（适用于内网 / 裸金属）
  * 可选：基于 BGP 的三层通告模式（适用于云厂商或复杂网络环境）
* CNI：`Cilium`
* 无需额外 LB 组件（更轻量）
* 更适合：
    * 内网
    * 裸金属
    * 资源受限或简化架构场景
* 原生支持 eBPF 网络能力

**执行方式：**

```bash
# 系统更新（可单独执行）
ansible-playbook -i inventory.ini site.yml --tags update -vv

# 集群完整初始化
ansible-playbook -i inventory.ini site.yml \
  --tags common,containerd,kube,kubevip,init,cli,cilium,kubevip-lb,join_masters,join_workers,nfs,dir \
  -vv
```

---

## 为什么选择 Ansible

当集群规模较小时，Shell 脚本尚可勉强使用；但在 **中大型集群** 场景下，Shell 脚本存在天然缺陷：

| 能力对比  | Shell | Ansible |
| ----- | ----- | ------- |
| 批量执行  | ❌     | ✅       |
| 幂等性   | ❌     | ✅       |
| 失败重试  | ❌     | ✅       |
| 状态可追踪 | ❌     | ✅       |
| 结构化管理 | ❌     | ✅       |
| 可维护性  | ❌     | ✅       |

因此，本项目以 **Ansible 为核心**，对 Kubernetes 初始化流程进行系统性工程重构。

---

## 项目特性

* ✅ 系统初始化（SELinux / Swap / 内核参数 / limits / journald）
* ✅ 批量系统升级与可控重启
* ✅ Containerd 安装与镜像加速
* ✅ Kubernetes 组件部署（kubeadm / kubelet / kubectl）
* ✅ 多种 HA 架构支持（nginx+keepalived / kube-vip）
* ✅ CNI 自动部署（Calico / Cilium）
* ✅ Master / Worker 自动加入
* ✅ 配置真实生效校验（非仅生成 YAML）
* ✅ kube-proxy 支持 nftables
* ✅ kubelet 日志策略可控

---

## 项目结构

> 采用 **标准 Ansible 目录结构 + 角色拆分**，便于维护与扩展

```text
├─ansible
│  ├─ansible-ssh-init
│  └─k8s-cluster-init-ansible
│      ├─group_vars
│      └─roles
│          ├─cli-tools
│          │  ├─files
│          │  ├─tasks
│          │  └─vars
│          ├─cni
│          │  ├─defaults
│          │  ├─files
│          │  ├─tasks
│          │  └─templates
│          ├─common
│          │  ├─check
│          │  └─tasks
│          ├─containerd
│          │  ├─files
│          │  ├─handlers
│          │  └─tasks
│          ├─dirs
│          │  ├─tasks
│          │  └─vars
│          ├─kube
│          │  └─tasks
│          ├─kube-vip
│          │  ├─defaults
│          │  ├─tasks
│          │  └─templates
│          ├─kube-vip-loadbalance
│          │  ├─defaults
│          │  ├─files
│          │  ├─tasks
│          │  └─templates
│          ├─kubeadm
│          │  ├─tasks
│          │  └─templates
│          ├─lb
│          │  ├─files
│          │  ├─tasks
│          │  └─templates
│          ├─nfs-server
│          │  ├─handlers
│          │  ├─tasks
│          │  └─vars
│          └─system_update
│              ├─defaults
│              ├─tasks
│              └─templates


```

---

## 设计理念

本项目遵循以下核心原则：

1. **声明式而非命令式**
2. **配置即文档**
3. **结果必须真实生效**
4. **不依赖隐式默认行为**
5. **为规模而设计，而非单机**

---

## 适用场景

* 多 Master Kubernetes 集群
* 高可用控制平面部署
* 云厂商自建 k8s
* 私有环境 / 内网 / 裸金属
* 生产环境预配置
* 批量环境快速交付

---

## 结语

本项目追求的不是“能跑起来”，而是以 **工程级标准** 构建 Kubernetes 初始化体系：

> 自动化的真正价值，不在于省几条命令，
> 而在于 **减少人为失误、提升一致性、增强可维护性**。
