from fastapi import FastAPI

from app.api.routes import router
from app.core.config import settings


def create_app() -> FastAPI:
    app = FastAPI(
        title="AIOps Agent",
        description="Alert-driven AIOps agent for Kubernetes operations.",
        version="0.1.0",
    )
    app.include_router(router, prefix="/api/v1")
    return app


app = create_app()


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok", "env": settings.aiops_env}
