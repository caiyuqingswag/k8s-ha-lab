from app.core.config import settings


class LokiTool:
    """Loki API facade with placeholder responses for MVP."""

    def __init__(self, base_url: str | None = None) -> None:
        self.base_url = base_url or settings.loki_url

    async def query_recent_errors(self, namespace: str, service: str) -> list[str]:
        return [
            f"[mock] {namespace}/{service}: connection refused from downstream dependency",
            f"[mock] {namespace}/{service}: readiness probe failed",
        ]
