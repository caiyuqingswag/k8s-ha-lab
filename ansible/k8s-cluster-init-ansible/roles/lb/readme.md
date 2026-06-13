# lb

该 role 用于在传统负载均衡节点上配置 Nginx 和 Keepalived，提供高可用入口或四层转发能力。

## 主要工作

- 安装 Nginx、Keepalived 等依赖。
- 渲染 `nginx.conf`。
- 渲染 `keepalived.conf`。
- 下发 `check_nginx.sh` 健康检查脚本。
- 启动并启用相关服务。

## 关键点

- 适合在需要自建入口 VIP 或 TCP/HTTP 转发时使用。
- 当前 `site.yml` 未直接编排该 role，如需使用可新增对应 play 或手动调用。

## 验证

```bash
systemctl status nginx
systemctl status keepalived
ip addr
```
