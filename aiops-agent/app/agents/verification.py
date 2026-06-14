from app.schemas.alerts import Alert
from app.schemas.incidents import Evidence, ExecutionResult, VerificationResult


class VerificationAgent:
    async def verify(self, alert: Alert, execution_results: list[ExecutionResult]) -> VerificationResult:
        dry_run_only = all(result.dry_run for result in execution_results)
        checks = [
            Evidence(
                source="verification",
                summary="Post-remediation checks are currently mocked.",
                details={
                    "alert": alert.alertname,
                    "dry_run_only": dry_run_only,
                    "executed_actions": len(execution_results),
                },
            )
        ]
        return VerificationResult(
            recovered=False if dry_run_only else True,
            checks=checks,
            summary="Dry-run mode cannot confirm production recovery."
            if dry_run_only
            else "Execution completed; telemetry should be checked for recovery.",
        )
