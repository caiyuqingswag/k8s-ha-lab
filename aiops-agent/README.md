# AIOps Agent

`aiops-agent` 是一个智能运维 Agent MVP，用于把告警接入、上下文采集、根因分析、决策、执行、验证和报告生成串成闭环。

当前版本默认使用 mock/fake URL 和 dry-run 执行策略，适合先在 `k8s-ha-lab` 中完成从 0 到 1 的骨架验证。

## 能力边界

- 接收 Alertmanager 风格 webhook。
- 查询 Prometheus/Loki/Tempo 的接口封装已经预留。
- Kubernetes 上下文采集接口已经预留。
- 生成根因分析、修复计划和事故报告。
- 执行动作默认 dry-run，不会真的修改集群。
- 后续可接入 LangGraph/OpenAI Agents SDK 做更复杂的多 Agent 编排。

## 本地启动

```bash
cd aiops-agent
python -m venv .venv
.venv\\Scripts\\activate
pip install -e .[dev]
copy .env.example .env
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 18080
```

Linux/macOS:

```bash
cd aiops-agent
python -m venv .venv
source .venv/bin/activate
pip install -e '.[dev]'
cp .env.example .env
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 18080
```

## 测试告警

```bash
curl -X POST http://127.0.0.1:18080/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d @tests/fixtures/service_down_alert.json
```

查看事件：

```bash
curl http://127.0.0.1:18080/api/v1/incidents
```

## 目录说明

```text
app/api/          HTTP API
app/agents/       感知、分析、决策、执行、验证、报告 Agent
app/tools/        Prometheus/Loki/Tempo/Kubernetes/执行工具封装
app/workflows/    告警处理闭环
configs/          默认配置示例
runbooks/         运维剧本
knowledge/        知识库资料
deploy/           Docker 和 Kubernetes 部署文件
tests/            测试和样例告警
```

## 下一步

1. 替换 `.env` 中的 Prometheus、Loki、Tempo、Grafana、Kubernetes 配置。
2. 把 mock 工具替换为真实查询。
3. 接入 LLM 做 RCA 总结和修复方案排序。
4. 增加审批流，把中高风险动作从 dry-run 改为人工确认后执行。
5. 把事故报告写入数据库和知识库，实现自我沉淀。

## Kubernetes 部署

构建镜像后，更新 [deploy/k8s/deployment.yaml](deploy/k8s/deployment.yaml) 中的镜像地址，然后部署：

```bash
kubectl apply -k deploy/k8s/
```

Alertmanager webhook 示例见 [configs/alertmanager-webhook.example.yaml](configs/alertmanager-webhook.example.yaml)。
