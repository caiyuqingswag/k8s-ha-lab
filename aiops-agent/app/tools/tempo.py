from app.core.config import settings


class TempoTool:
    """Tempo API facade with placeholder trace summaries."""

    def __init__(self, base_url: str | None = None) -> None:
        self.base_url = base_url or settings.tempo_url

    async def query_trace_summary(self, namespace: str, service: str) -> dict[str, str]:
        return {
            "source": self.base_url,
            "namespace": namespace,
            "service": service,
            "slow_span": "dependency.redis",
            "error_span": "service.call",
        }
