from app.schemas.alerts import Alert
from app.schemas.incidents import IncidentAnalysis, IncidentDecision, RemediationAction


class DecisionAgent:
    async def decide(self, alert: Alert, analysis: IncidentAnalysis) -> IncidentDecision:
        namespace = alert.namespace or "default"
        service = alert.service or "unknown-service"
        actions: list[RemediationAction] = []

        if "no ready endpoints" in analysis.suspected_root_cause.lower():
            actions.append(
                RemediationAction(
                    name="rollout_status",
                    description="Check rollout status for the affected workload.",
                    risk="low",
                    command=f"kubectl -n {namespace} rollout status deploy/{service} --timeout=120s",
                )
            )
            actions.append(
                RemediationAction(
                    name="restart_workload",
                    description="Restart the affected stateless workload.",
                    risk="medium",
                    command=f"kubectl -n {namespace} rollout restart deploy/{service}",
                    requires_approval=True,
                )
            )
        elif "redis" in analysis.suspected_root_cause.lower():
            actions.append(
                RemediationAction(
                    name="check_redis_sentinel",
                    description="Check Redis Sentinel master and replica status.",
                    risk="low",
                    command=f"kubectl -n {namespace} get pod,svc -l app=redis",
                )
            )
        else:
            actions.append(
                RemediationAction(
                    name="collect_more_context",
                    description="Collect more Kubernetes events, logs, metrics, and recent changes.",
                    risk="low",
                )
            )

        auto_executable = all(action.risk == "low" and not action.requires_approval for action in actions)
        return IncidentDecision(
            recommended_actions=actions,
            rationale="Actions are selected from the current root-cause hypothesis and risk policy.",
            auto_executable=auto_executable,
        )
