# kubeadm

该 role 负责用 kubeadm 初始化首个控制平面节点，并把其他 master、worker 节点加入集群。

## 主要工作

- `init.yml`: 渲染 `kubeadm-init.yaml`，执行 `kubeadm init`，准备 kubeconfig 和 join 命令。
- `join_masters.yml`: 让其他控制平面节点以 control-plane 方式加入集群。
- `join_workers.yml`: 让 worker 节点加入集群。
- 处理证书、token、discovery hash 和 kubelet 状态。

## 关键变量

- `k8s_cluster_name`: 集群名称，默认 `prod-hz-01`。
- `k8s_version`: Kubernetes 版本，默认 `1.36.1`。
- `control_plane_endpoint`: 控制面入口，通常是 kube-vip VIP 加 6443。
- `pod_cidr` / `service_cidr`: Pod 和 Service 网段。
- `cri_socket`: containerd CRI socket。
- `kubeadm_skip_kube_proxy`: 是否跳过 kube-proxy，默认 `true`，配合 Cilium kube-proxy replacement。

## 执行方式

初始化首个 master：

```bash
ansible-playbook -i inventory.ini site.yml --tags init
```

加入其他 master：

```bash
ansible-playbook -i inventory.ini site.yml --tags join_masters
```

加入 worker：

```bash
ansible-playbook -i inventory.ini site.yml --tags join_workers
```

## 验证

```bash
kubectl get nodes -o wide
kubectl -n kube-system get pods
```
