# Gateway API

本目录用于管理和实践 Kubernetes **Gateway API** 相关的部署方式、路由规则以及后续扩展能力。Gateway API 是 Kubernetes 官方推出的新一代流量入口与服务暴露标准，用于逐步替代传统 Ingress 在复杂场景下的不足。

该目录的目标是：

* 探索和引入 Gateway API 作为未来统一入口方案
* 规范流量接入方式
* 提供可扩展、可治理的流量管理能力
* 为后续复杂路由与多团队协作做好准备

---

## 一、什么是 Gateway API

Gateway API 是 Kubernetes SIG-Network 官方推出的下一代网络接口规范，主要用于：

* 服务对外暴露
* L7/L4 流量路由
* TLS 管理
* 权限与责任解耦
* 多租户支持

相比 Ingress，Gateway API 提供了更清晰的资源模型、更强的表达能力和更好的扩展性。

---

## 二、核心资源说明

Gateway API 主要由以下资源组成：

| 资源           | 作用                        |
| ------------ | ------------------------- |
| GatewayClass | 定义网关实现类型（由 Controller 提供） |
| Gateway      | 定义网关实例（监听端口、TLS 等）        |
| HTTPRoute    | HTTP 路由规则                 |
| TCPRoute     | TCP 路由规则                  |
| UDPRoute     | UDP 路由规则                  |
| TLSRoute     | TLS 路由规则                  |

这些资源通过清晰的层级关系进行组合，构成完整的流量治理体系。

---

## 三、与 Ingress 的区别

| 维度         | Ingress    | Gateway API |
| ---------- | ---------- | ----------- |
| 成熟度        | 高          | 中           |
| 表达能力       | 一般         | 强           |
| 扩展方式       | Annotation | 原生 CRD      |
| 权限模型       | 弱          | 强           |
| TCP/UDP 支持 | 弱          | 强           |
| 多租户        | 不友好        | 友好          |

Gateway API 更适合复杂场景和大型集群。

---

## 四、目录结构

```
gateway-api/
├── gatewayclasses/     # GatewayClass 定义
├── gateways/           # Gateway 实例
├── httproutes/         # HTTP 路由
├── tcproutes/          # TCP 路由
├── tls/                # TLS 配置
├── examples/           # 示例
└── README.md
```

---

## 五、基本架构模型

Gateway API 的核心模型如下：

```
Client → Gateway → Route → Service → Pod
```

其中：

* Gateway 负责监听端口、TLS、协议
* Route 负责路由匹配规则
* Service 负责后端服务发现

---

## 六、适用场景

Gateway API 适合以下场景：

* 大规模集群
* 多团队共享入口
* 复杂路由规则
* 需要精细化权限控制
* 需要 TCP/UDP 原生支持
* 多协议混合

---

## 七、当前使用策略

在本项目中，Gateway API 作为**未来演进方向**，当前主要用于：

* 方案验证
* 技术预研
* 小规模试点
* 架构演进准备

生产环境仍以 Nodeport 为主。
