from pydantic import BaseModel, Field


class Evidence(BaseModel):
    source: str
    summary: str
    details: dict[str, str | int | float | bool | None] = Field(default_factory=dict)


class RemediationAction(BaseModel):
    name: str
    description: str
    risk: str = "low"
    command: str | None = None
    requires_approval: bool = False


class IncidentAnalysis(BaseModel):
    summary: str
    suspected_root_cause: str
    confidence: float = 0.5
    evidences: list[Evidence] = Field(default_factory=list)


class IncidentDecision(BaseModel):
    recommended_actions: list[RemediationAction] = Field(default_factory=list)
    rationale: str
    auto_executable: bool = False


class ExecutionResult(BaseModel):
    action: str
    status: str
    output: str
    dry_run: bool = True


class VerificationResult(BaseModel):
    recovered: bool
    checks: list[Evidence] = Field(default_factory=list)
    summary: str
