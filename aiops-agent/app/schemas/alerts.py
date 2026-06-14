from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

from pydantic import BaseModel, Field


class Alert(BaseModel):
    status: str = "firing"
    labels: dict[str, str] = Field(default_factory=dict)
    annotations: dict[str, str] = Field(default_factory=dict)
    startsAt: datetime | None = None
    endsAt: datetime | None = None
    generatorURL: str | None = None

    @property
    def alertname(self) -> str:
        return self.labels.get("alertname", "UnknownAlert")

    @property
    def namespace(self) -> str | None:
        return self.labels.get("namespace")

    @property
    def service(self) -> str | None:
        return self.labels.get("service") or self.labels.get("app")


class AlertmanagerWebhook(BaseModel):
    receiver: str | None = None
    status: str | None = None
    alerts: list[Alert] = Field(default_factory=list)
    groupLabels: dict[str, str] = Field(default_factory=dict)
    commonLabels: dict[str, str] = Field(default_factory=dict)
    commonAnnotations: dict[str, str] = Field(default_factory=dict)
    externalURL: str | None = None
    version: str | None = None
    groupKey: str | None = None
    truncatedAlerts: int | None = None


class IncidentRecord(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    title: str
    status: str = "open"
    severity: str = "warning"
    alert: Alert
    result: dict[str, Any] = Field(default_factory=dict)
