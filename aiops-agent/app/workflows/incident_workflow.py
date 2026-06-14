from app.agents.decision import DecisionAgent
from app.agents.perception import PerceptionAgent
from app.agents.rca import RootCauseAgent
from app.agents.remediation import RemediationAgent
from app.agents.report import ReportAgent
from app.agents.verification import VerificationAgent
from app.schemas.alerts import Alert


class IncidentWorkflow:
    def __init__(
        self,
        perception: PerceptionAgent | None = None,
        rca: RootCauseAgent | None = None,
        decision: DecisionAgent | None = None,
        remediation: RemediationAgent | None = None,
        verification: VerificationAgent | None = None,
        report: ReportAgent | None = None,
    ) -> None:
        self.perception = perception or PerceptionAgent()
        self.rca = rca or RootCauseAgent()
        self.decision = decision or DecisionAgent()
        self.remediation = remediation or RemediationAgent()
        self.verification = verification or VerificationAgent()
        self.report = report or ReportAgent()

    async def run(self, alert: Alert) -> dict[str, object]:
        evidences = await self.perception.collect(alert)
        analysis = await self.rca.analyze(alert, evidences)
        decision = await self.decision.decide(alert, analysis)
        execution_results = await self.remediation.execute(decision)
        verification = await self.verification.verify(alert, execution_results)
        report = await self.report.build_report(
            alert=alert,
            analysis=analysis,
            decision=decision,
            execution_results=execution_results,
            verification=verification,
        )
        return {
            "analysis": analysis.model_dump(),
            "decision": decision.model_dump(),
            "execution": [result.model_dump() for result in execution_results],
            "verification": verification.model_dump(),
            "report": report,
        }
