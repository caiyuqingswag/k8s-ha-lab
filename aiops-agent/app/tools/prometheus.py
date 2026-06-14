from app.core.config import settings


class PrometheusTool:
    """Prometheus API facade.

    The MVP returns deterministic placeholder data. Replace query methods with real
    HTTP calls after PROMETHEUS_URL is available.
    """

    def __init__(self, base_url: str | None = None) -> None:
        self.base_url = base_url or settings.prometheus_url

    async def query_service_health(self, namespace: str, service: str) -> dict[str, str]:
        return {
            "source": self.base_url,
            "namespace": namespace,
            "service": service,
            "up": "0",
            "error_rate": "high",
            "latency_p95": "unknown",
        }
