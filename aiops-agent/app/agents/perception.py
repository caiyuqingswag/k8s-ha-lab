from app.schemas.alerts import Alert
from app.schemas.incidents import Evidence
from app.tools.kubernetes import KubernetesTool
from app.tools.loki import LokiTool
from app.tools.prometheus import PrometheusTool
from app.tools.tempo import TempoTool


class PerceptionAgent:
    def __init__(
        self,
        prometheus: PrometheusTool | None = None,
        loki: LokiTool | None = None,
        tempo: TempoTool | None = None,
        kubernetes: KubernetesTool | None = None,
    ) -> None:
        self.prometheus = prometheus or PrometheusTool()
        self.loki = loki or LokiTool()
        self.tempo = tempo or TempoTool()
        self.kubernetes = kubernetes or KubernetesTool()

    async def collect(self, alert: Alert) -> list[Evidence]:
        namespace = alert.namespace or "default"
        service = alert.service or "unknown-service"

        metrics = await self.prometheus.query_service_health(namespace, service)
        logs = await self.loki.query_recent_errors(namespace, service)
        trace = await self.tempo.query_trace_summary(namespace, service)
        k8s = await self.kubernetes.get_workload_context(namespace, service)

        return [
            Evidence(source="alertmanager", summary=alert.alertname, details=alert.labels),
            Evidence(source="prometheus", summary="Service health metrics collected.", details=metrics),
            Evidence(source="loki", summary="Recent error logs collected.", details={"logs": "\n".join(logs)}),
            Evidence(source="tempo", summary="Trace summary collected.", details=trace),
            Evidence(source="kubernetes", summary="Workload context collected.", details=k8s),
        ]
