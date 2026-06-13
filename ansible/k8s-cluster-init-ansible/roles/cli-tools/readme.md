# cli-tools

该 role 在首个 master 上安装集群运维常用 CLI，包括 Helm、Cilium CLI、Hubble CLI 以及 bash completion。

## 主要工作

- 检查目标主机上是否已安装对应二进制。
- 从 role 的 `files` 目录复制离线压缩包。
- 解压并安装到 `/usr/local/bin`。
- 安装 `bash-completion`。
- 生成 `kubectl`、`helm`、`cilium`、`hubble` 的 shell 补全。

## 关键变量

- `cli_tools_target_host`: 安装目标主机，默认首个 master。
- `helm_version`: Helm 版本，默认 `v4.0.4`。
- `cilium_cli_archive`: Cilium CLI 离线包。
- `hubble_cli_enabled`: 是否安装 Hubble CLI，默认 `true`。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags cli
```

## 验证

```bash
helm version
cilium version
hubble version
```
