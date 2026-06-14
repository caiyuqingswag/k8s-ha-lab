from app.schemas.incidents import ExecutionResult, IncidentDecision
from app.tools.executor import ExecutorTool


class RemediationAgent:
    def __init__(self, executor: ExecutorTool | None = None) -> None:
        self.executor = executor or ExecutorTool()

    async def execute(self, decision: IncidentDecision) -> list[ExecutionResult]:
        results: list[ExecutionResult] = []
        for action in decision.recommended_actions:
            if action.risk == "high":
                results.append(
                    ExecutionResult(
                        action=action.name,
                        status="blocked",
                        output="High-risk action blocked by policy.",
                        dry_run=self.executor.dry_run,
                    )
                )
                continue
            results.append(await self.executor.execute(action))
        return results
