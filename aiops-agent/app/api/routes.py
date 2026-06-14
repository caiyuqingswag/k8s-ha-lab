from fastapi import APIRouter, HTTPException

from app.schemas.alerts import Alert, AlertmanagerWebhook, IncidentRecord
from app.services.incident_store import incident_store
from app.workflows.incident_workflow import IncidentWorkflow

router = APIRouter()


@router.post("/alerts", response_model=list[IncidentRecord])
async def receive_alerts(payload: AlertmanagerWebhook) -> list[IncidentRecord]:
    workflow = IncidentWorkflow()
    incidents: list[IncidentRecord] = []

    for alert in payload.alerts:
        result = await workflow.run(alert)
        title = f"{alert.alertname}: {alert.namespace or 'unknown'}/{alert.service or 'unknown'}"
        incident = IncidentRecord(
            title=title,
            severity=alert.labels.get("severity", "warning"),
            alert=alert,
            result=result,
        )
        incidents.append(incident_store.add(incident))

    return incidents


@router.post("/alerts/single", response_model=IncidentRecord)
async def receive_single_alert(alert: Alert) -> IncidentRecord:
    workflow = IncidentWorkflow()
    result = await workflow.run(alert)
    incident = IncidentRecord(
        title=f"{alert.alertname}: {alert.namespace or 'unknown'}/{alert.service or 'unknown'}",
        severity=alert.labels.get("severity", "warning"),
        alert=alert,
        result=result,
    )
    return incident_store.add(incident)


@router.get("/incidents", response_model=list[IncidentRecord])
async def list_incidents() -> list[IncidentRecord]:
    return incident_store.list()


@router.get("/incidents/{incident_id}", response_model=IncidentRecord)
async def get_incident(incident_id: str) -> IncidentRecord:
    incident = incident_store.get(incident_id)
    if incident is None:
        raise HTTPException(status_code=404, detail="Incident not found")
    return incident
