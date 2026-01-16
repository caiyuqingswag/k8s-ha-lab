## 目录说明

```text
k8s-cluster-init-ansible/
├── inventory.ini                 # 主机清单
├── site.yml                      # Ansible 统一入口
├── readme.md                     # 项目说明文档
│
├── group_vars/
│   └── all.yml                   # 全局变量配置
│
├── roles/
│   ├── common/                   # 操作系统初始化与调优
│   ├── containerd/               # Containerd 安装与配置
│   ├── kube/                     # kubelet / kubeadm / kubectl 安装
│   ├── kubeadm/                  # kubeadm 初始化与节点加入
│   ├── cni/                      # CNI 网络插件
│   ├── lb/                       # 负载均衡（Nginx + Keepalived）
│   └── system_update/            # 系统升级与智能重启控制
│
└── upgrade-reports/              # 系统升级报告输出目录
```

---

## 执行顺序说明（非常重要）

整个集群初始化流程按以下顺序执行，每一步都可以单独运行，也可以组合执行。

---

### 1️⃣ 系统升级与内核更新（推荐先执行）

该步骤用于统一所有节点的系统环境，包括：

* 系统软件升级
* 内核升级
* 判断是否需要重启
* 自动生成升级报告

```bash
ansible-playbook -i inventory.ini site.yml --tags update -vv
```

---

### 2️⃣ 系统初始化与调优

包含：

* 关闭 SELinux / Swap
* 内核参数调优
* limits / journald 配置
* 基础工具安装

```bash
ansible-playbook -i inventory.ini site.yml --tags common
```

---

### 3️⃣ 部署负载均衡（HA 场景） /后续会建新分支来做部署kube-vip作为HA实现控制平面高可用

使用 Nginx + Keepalived 实现控制平面高可用。

```bash
ansible-playbook -i inventory.ini site.yml --tags lb
```

---

### 4️⃣ 安装 Container Runtime

包含：

* containerd 安装
* 镜像加速配置
* crictl 配置

```bash
ansible-playbook -i inventory.ini site.yml --tags containerd
```

---

### 5️⃣ 安装 Kubernetes 组件

包含：

* kubelet
* kubeadm
* kubectl

```bash
ansible-playbook -i inventory.ini site.yml --tags kube
```

---

### 6️⃣ 初始化第一个 Master 节点

该步骤会：

* 生成 kubeadm 配置
* 初始化集群
* 部署 CNI
* 生成 join 信息

```bash
ansible-playbook -i inventory.ini site.yml --tags init
```

---

### 7️⃣ 加入其他 Master（控制平面）

```bash
ansible-playbook -i inventory.ini site.yml --tags join_masters
```

---

### 8️⃣ 加入 Worker 节点

```bash
ansible-playbook -i inventory.ini site.yml --tags join_workers
```

---

## 推荐的完整执行流程

如果是从零开始初始化集群，推荐按以下顺序执行：

```bash
ansible-playbook -i inventory.ini site.yml --tags update -vv
# 重启后
ansible-playbook -i inventory.ini site.yml --tags common
ansible-playbook -i inventory.ini site.yml --tags lb
ansible-playbook -i inventory.ini site.yml --tags containerd
ansible-playbook -i inventory.ini site.yml --tags kube
ansible-playbook -i inventory.ini site.yml --tags init
ansible-playbook -i inventory.ini site.yml --tags join_masters
ansible-playbook -i inventory.ini site.yml --tags join_workers
```

---

## 设计理念

* 声明式，而非命令式
* 所有关键配置可追溯
* 不依赖默认行为
* 支持幂等执行
* 为规模而设计

---

## 项目价值

相较于传统的 Shell 脚本方式，本项目具有以下优势：

| 对比项   | Shell | Ansible |
| ----- | ----- | ------- |
| 批量执行  | ❌     | ✅       |
| 幂等性   | ❌     | ✅       |
| 失败重试  | ❌     | ✅       |
| 状态可追踪 | ❌     | ✅       |
| 可维护性  | ❌     | ✅       |
| 大规模支持 | ❌     | ✅       |

---

## 总结

本项目通过 Ansible 将 Kubernetes 集群初始化流程工程化，使其具备：

* 可维护性
* 可重复性
* 可验证性
* 可扩展性

适用于中大型集群初始化及生产环境标准化部署。

---
