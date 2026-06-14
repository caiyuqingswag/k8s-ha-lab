from app.schemas.alerts import Alert
from app.schemas.incidents import Evidence, IncidentAnalysis


class RootCauseAgent:
    async def analyze(self, alert: Alert, evidences: list[Evidence]) -> IncidentAnalysis:
        evidence_text = " ".join(
            [e.summary + " " + " ".join(str(v) for v in e.details.values()) for e in evidences]
        ).lower()

        if "service_endpoints 0" in evidence_text or "endpoints" in evidence_text:
            root_cause = "Service has no ready endpoints, likely caused by unhealthy pods."
            confidence = 0.75
        elif "redis" in evidence_text:
            root_cause = "Downstream Redis dependency appears unhealthy or unreachable."
            confidence = 0.65
        elif "crashloopbackoff" in evidence_text:
            root_cause = "Workload pods are restarting repeatedly."
            confidence = 0.7
        else:
            root_cause = "Root cause is unclear; more environment-specific telemetry is required."
            confidence = 0.4

        return IncidentAnalysis(
            summary=f"{alert.alertname} detected for {alert.namespace or 'unknown namespace'}.",
            suspected_root_cause=root_cause,
            confidence=confidence,
            evidences=evidences,
        )
