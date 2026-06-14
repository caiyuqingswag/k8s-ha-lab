import pytest

from app.schemas.alerts import Alert
from app.workflows.incident_workflow import IncidentWorkflow


@pytest.mark.asyncio
async def test_incident_workflow_generates_report() -> None:
    alert = Alert(
        labels={
            "alertname": "ServiceDown",
            "namespace": "prod-distributed",
            "service": "order-api",
            "severity": "critical",
        }
    )
    result = await IncidentWorkflow().run(alert)

    assert "analysis" in result
    assert "decision" in result
    assert "execution" in result
    assert "Incident Report" in result["report"]
