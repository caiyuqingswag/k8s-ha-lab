# kube

该 role 在所有节点安装 kubelet、kubeadm、kubectl 等 Kubernetes 节点组件。

## 主要工作

- 配置 Kubernetes apt 源。
- 安装指定版本的 kubelet、kubeadm、kubectl。
- 锁定 Kubernetes 包版本，避免系统升级时意外升级。
- 启用 kubelet 服务。

## 关键变量

- `k8s_version`: Kubernetes 包版本，默认 `1.36.1`。
- `k8s_minor_version`: Kubernetes apt 源小版本，默认 `1.36`。
- `image_repo`: kubeadm 预拉取控制面镜像仓库。
- `k8s_apt_repo_base`: Kubernetes apt 源地址，默认使用阿里云镜像。
- `kubeadm_prepull_images`: 是否在 master 上预拉取控制面镜像。
- 该 role 只负责安装二进制和服务，不执行 `kubeadm init` 或 `join`。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags kube
```

## 验证

```bash
kubeadm version
kubectl version --client
systemctl status kubelet
```
