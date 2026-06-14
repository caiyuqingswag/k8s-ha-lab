from app.core.config import settings


class KubernetesTool:
    """Kubernetes facade.

    Real implementation can use the official kubernetes Python client. This MVP keeps
    outputs deterministic so the incident workflow is safe to run anywhere.
    """

    def __init__(self, mode: str | None = None) -> None:
        self.mode = mode or settings.kubernetes_mode

    async def get_workload_context(self, namespace: str, service: str) -> dict[str, str]:
        return {
            "mode": self.mode,
            "namespace": namespace,
            "service": service,
            "deployment_ready": "false",
            "pod_phase": "CrashLoopBackOff",
            "service_endpoints": "0",
            "recent_event": "Readiness probe failed",
        }
