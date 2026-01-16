# Kubernetes HA Cluster Initialization with Ansible

## 项目简介

本项目使用 **Ansible** 自动化完成 Kubernetes 高可用（HA）集群的初始化与基础环境部署，替代传统的手工 Shell 脚本方式，实现**标准化、批量化、可重复、可审计**的集群初始化流程。

为了进一步减少人工输入命令和人为错误的风险，本项目从最初的 **Shell 脚本部署方式** 升级为 **以 Ansible 为核心的自动化方案**，在几十台甚至上百台服务器规模的场景下，大幅提升了初始化效率和稳定性。

---

## 项目目标

*  实现 Kubernetes 集群的**全自动初始化**
*  ️自动完成系统调优、容器运行时、Kubernetes 组件部署
*  支持高可用架构（VIP / LB / 多 Master）
*  使用国内镜像源加速拉取
*  所有关键配置可追溯、可验证
*  支持幂等执行，重复运行不会破坏环境
*  显著减少大规模服务器初始化时间

---

## 为什么选择 Ansible

在集群规模较小时，Shell 脚本尚可接受；但随着节点数量增长，Shell 方式会暴露出明显问题：

| 问题    | Shell | Ansible |
| ----- | ----- | ------- |
| 批量执行  | ❌     | ✅       |
| 幂等性   | ❌     | ✅       |
| 失败重试  | ❌     | ✅       |
| 状态可追踪 | ❌     | ✅       |
| 结构化管理 | ❌     | ✅       |
| 可维护性  | ❌     | ✅       |

因此，本项目选择使用 **Ansible** 作为主要自动化工具，对整个集群初始化流程进行工程化重构。

---

## 项目特性

* ✅ 系统初始化（SELinux / Swap / 内核参数 / limits / journald）
* ✅ 批量系统升级与智能重启控制
* ✅ Containerd 安装与镜像加速
* ✅ Kubernetes 组件部署（kubeadm / kubelet / kubectl）
* ✅ HA 架构支持（LB / VIP）
* ✅ CNI 自动部署
* ✅ 节点自动加入集群
* ✅ 配置真实生效可验证（非仅 YAML）
* ✅ 支持 nftables 模式的 kube-proxy
* ✅ kubelet 日志策略可控

---

## 项目结构（示例）

```text
scripts/
├── ansible/
│   ├── readme.md
│   │
│   ├── ansible-ssh-init/
│   │   ├── hosts.ini
│   │   └── install_ansible.sh
│   │
│   ├── k8s-cluster-init-ansible/
│   │   ├── add-workers.yml
│   │   ├── inventory.ini
│   │   ├── readme.md
│   │   ├── site.yml
│   │   │
│   │   ├── group_vars/
│   │   │   └── all.yml
│   │   │
│   │   ├── roles/
│   │   │   ├── common/
│   │   │   │   ├── check/
│   │   │   │   │   └── check.sh
│   │   │   │   ├── files/
│   │   │   │   ├── tasks/
│   │   │   │   │   └── main.yml
│   │   │   │   └── templates/
│   │   │   │
│   │   │   ├── containerd/
│   │   │   │   ├── files/
│   │   │   │   │   ├── config.toml
│   │   │   │   │   └── crictl-v1.34.0-linux-amd64.tar.gz
│   │   │   │   ├── handlers/
│   │   │   │   │   └── main.yml
│   │   │   │   ├── tasks/
│   │   │   │   │   └── main.yml
│   │   │   │   └── templates/
│   │   │   │
│   │   │   ├── kube/
│   │   │   │   ├── files/
│   │   │   │   ├── tasks/
│   │   │   │   │   └── main.yml
│   │   │   │   └── templates/
│   │   │   │
│   │   │   ├── kubeadm/
│   │   │   │   ├── files/
│   │   │   │   ├── tasks/
│   │   │   │   │   ├── init.yml
│   │   │   │   │   ├── join_masters.yml
│   │   │   │   │   └── join_workers.yml
│   │   │   │   └── templates/
│   │   │   │       └── kubeadm.yaml.j2
│   │   │   │
│   │   │   ├── lb/
│   │   │   │   ├── files/
│   │   │   │   │   └── check_nginx.sh
│   │   │   │   ├── tasks/
│   │   │   │   │   └── main.yml
│   │   │   │   └── templates/
│   │   │   │       ├── keepalived.conf.j2
│   │   │   │       └── nginx.conf.j2
│   │   │   │
│   │   │   └── system_update/
│   │   │       ├── defaults/
│   │   │       │   └── main.yml
│   │   │       ├── tasks/
│   │   │       │   └── main.yml
│   │   │       └── templates/
│   │   │           └── summary.j2
│   │   │
│   │   └── upgrade-reports/
│   │
│   └── k8s-tools-install/
│       ├── helm-v4.0.4-linux-amd64.tar.gz
│       ├── install-completion.sh
│       └── install_helm_local.sh
│
└── nfs/
    └── install_nfs_server.sh


```

---

## 设计理念

本项目遵循以下原则：

1. **声明式而非命令式**
2. **配置即文档**
3. **真实生效可验证**
4. **不依赖默认行为**
5. **为规模而设计**

---

## 适用场景

* 多节点 Kubernetes 集群初始化
* 高可用控制平面部署
* 云厂商自建k8s
* 内网环境
* 生产环境预配置
* 批量环境初始化

---

## 结语

本项目不是简单的“能跑起来”，而是以**工程级标准**构建 Kubernetes 初始化体系：

> 自动化不是为了炫技，而是为了减少人为干预、提升稳定性、增强可维护性。

