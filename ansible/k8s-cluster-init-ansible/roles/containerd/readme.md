# containerd

该 role 在所有节点安装并配置 containerd，提供 Kubernetes 使用的 CRI 运行时。

## 主要工作

- 停止并清理旧 containerd 包。
- 配置 Docker CE apt 源和 keyring。
- 安装 containerd。
- 下发 `config.toml`。
- 安装 `crictl`。
- 重启并启用 containerd。
- 可选拉取 pause 镜像做运行时连通性测试。

## 关键变量

- `crictl_version`: crictl 版本，默认 `v1.34.0`。
- `containerd_pull_pause_test`: 是否拉取 pause 镜像测试，默认 `true`。
- `containerd_pause_image`: pause 镜像地址，默认使用阿里云镜像。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags containerd
```

## 验证

```bash
systemctl status containerd
crictl info
crictl images
```
