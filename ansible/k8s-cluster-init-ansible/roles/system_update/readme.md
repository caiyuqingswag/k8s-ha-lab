# system_update

该 role 对 Ubuntu 节点执行系统升级、清理和按需重启，并在本地生成升级报告。

## 主要工作

- 记录升级前 OS 和 kernel 版本。
- 执行 apt cache 更新和 `dist` 升级。
- 可选执行 autoremove 和 autoclean。
- 判断是否需要重启。
- 按配置跳过或处理控制节点重启。
- 等待节点重启后恢复连接。
- 渲染升级摘要报告。

## 关键变量

- `system_update_enabled`: 是否启用系统更新，默认 `true`。
- `system_update_reboot`: 是否允许重启，默认 `true`。
- `system_update_reboot_only_if_needed`: 仅在需要时重启，默认 `true`。
- `system_update_control_host`: Ansible 控制节点主机名，默认 `master1`。
- `system_update_report_dir`: 报告输出目录，默认 `./upgrade-reports`。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags update
```

## 验证

```bash
cat /etc/os-release
uname -r
```
