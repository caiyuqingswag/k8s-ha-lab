from datetime import datetime, timezone

from app.schemas.alerts import Alert
from app.schemas.incidents import (
    ExecutionResult,
    IncidentAnalysis,
    IncidentDecision,
    VerificationResult,
)


class ReportAgent:
    async def build_report(
        self,
        alert: Alert,
        analysis: IncidentAnalysis,
        decision: IncidentDecision,
        execution_results: list[ExecutionResult],
        verification: VerificationResult,
    ) -> str:
        lines = [
            "# Incident Report",
            "",
            f"- Generated At: {datetime.now(timezone.utc).isoformat()}",
            f"- Alert: {alert.alertname}",
            f"- Namespace: {alert.namespace or 'unknown'}",
            f"- Service: {alert.service or 'unknown'}",
            f"- Status: {alert.status}",
            "",
            "## Summary",
            analysis.summary,
            "",
            "## Suspected Root Cause",
            f"{analysis.suspected_root_cause} (confidence: {analysis.confidence:.2f})",
            "",
            "## Evidence",
        ]
        for evidence in analysis.evidences:
            lines.append(f"- {evidence.source}: {evidence.summary}")

        lines.extend(["", "## Decision", decision.rationale, "", "## Actions"])
        for action in decision.recommended_actions:
            lines.append(f"- {action.name}: {action.description} risk={action.risk}")

        lines.extend(["", "## Execution"])
        for result in execution_results:
            lines.append(f"- {result.action}: {result.status}; {result.output}")

        lines.extend(["", "## Verification", verification.summary, "", "## Follow-ups"])
        lines.append("- Review runbook coverage for this incident type.")
        lines.append("- Add missing alerts, dashboards, or automation if the diagnosis was incomplete.")
        return "\n".join(lines)
