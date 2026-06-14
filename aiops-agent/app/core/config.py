from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    aiops_env: str = Field(default="dev", alias="AIOPS_ENV")
    aiops_log_level: str = Field(default="INFO", alias="AIOPS_LOG_LEVEL")
    aiops_dry_run: bool = Field(default=True, alias="AIOPS_DRY_RUN")

    llm_provider: str = Field(default="openai", alias="LLM_PROVIDER")
    llm_model: str = Field(default="gpt-4.1-mini", alias="LLM_MODEL")
    llm_api_key: str = Field(default="CHANGE_ME", alias="LLM_API_KEY")
    llm_base_url: str = Field(default="https://api.openai.com/v1", alias="LLM_BASE_URL")

    prometheus_url: str = Field(default="http://prometheus.example.local", alias="PROMETHEUS_URL")
    loki_url: str = Field(default="http://loki.example.local", alias="LOKI_URL")
    tempo_url: str = Field(default="http://tempo.example.local", alias="TEMPO_URL")
    grafana_url: str = Field(default="http://grafana.example.local", alias="GRAFANA_URL")

    kubernetes_mode: str = Field(default="in_cluster", alias="KUBERNETES_MODE")
    kubeconfig_path: str | None = Field(default=None, alias="KUBECONFIG_PATH")
    default_namespace: str = Field(default="default", alias="DEFAULT_NAMESPACE")

    allow_auto_execute_low_risk: bool = Field(default=True, alias="ALLOW_AUTO_EXECUTE_LOW_RISK")
    require_approval_for_medium_risk: bool = Field(
        default=True, alias="REQUIRE_APPROVAL_FOR_MEDIUM_RISK"
    )
    deny_high_risk_execution: bool = Field(default=True, alias="DENY_HIGH_RISK_EXECUTION")

    postgres_dsn: str = Field(
        default="postgresql://aiops:CHANGE_ME@postgres.example.local:5432/aiops",
        alias="POSTGRES_DSN",
    )
    redis_url: str = Field(default="redis://redis.example.local:6379/0", alias="REDIS_URL")
    qdrant_url: str = Field(default="http://qdrant.example.local:6333", alias="QDRANT_URL")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
