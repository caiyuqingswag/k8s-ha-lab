# istio-traffic-policies

该 role 用于下发 Istio 流量治理策略，例如灰度权重、超时、重试、连接池和熔断。

## 主要工作

- 在首个 master 上创建工作目录。
- 根据 `istio_traffic_policies` 渲染 `DestinationRule` 和 `VirtualService`。
- 等待 kube-apiserver 可访问。
- 应用流量治理清单。

## 关键变量

- `istio_traffic_policies_work_dir`: 清单生成目录。
- `istio_traffic_policies`: 业务服务的流量策略列表。
- 策略中通常包含 host、subset、weight、timeout、retries、connectionPool、outlierDetection 等配置。

## 执行方式

```bash
ansible-playbook -i inventory.ini site.yml --tags istio-traffic-policies
```

## 验证

```bash
kubectl get destinationrule,virtualservice -A
```
