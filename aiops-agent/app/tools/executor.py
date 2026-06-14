from app.core.config import settings
from app.schemas.incidents import ExecutionResult, RemediationAction


class ExecutorTool:
    """Controlled remediation executor.

    The default mode is dry-run. Real kubectl/helm/ansible execution should be added
    behind approval checks.
    """

    def __init__(self, dry_run: bool | None = None) -> None:
        self.dry_run = settings.aiops_dry_run if dry_run is None else dry_run

    async def execute(self, action: RemediationAction) -> ExecutionResult:
        if self.dry_run:
            return ExecutionResult(
                action=action.name,
                status="dry_run",
                output=f"Would execute: {action.command or action.description}",
                dry_run=True,
            )

        if action.requires_approval:
            return ExecutionResult(
                action=action.name,
                status="blocked",
                output="Action requires approval.",
                dry_run=False,
            )

        return ExecutionResult(
            action=action.name,
            status="executed",
            output=f"Executed: {action.command or action.description}",
            dry_run=False,
        )
