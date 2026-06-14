from openai import AsyncOpenAI

from app.core.config import settings


class LLMTool:
    """LLM facade.

    It safely falls back to deterministic text when no real API key is configured.
    """

    def __init__(self) -> None:
        self.enabled = settings.llm_api_key not in {"", "CHANGE_ME"}
        self.client = AsyncOpenAI(api_key=settings.llm_api_key, base_url=settings.llm_base_url)

    async def summarize_incident(self, prompt: str) -> str:
        if not self.enabled:
            return "[mock-llm] LLM is not configured. Using rule-based incident summary."

        response = await self.client.chat.completions.create(
            model=settings.llm_model,
            messages=[
                {
                    "role": "system",
                    "content": "You are an AIOps incident analyst. Be concise and operational.",
                },
                {"role": "user", "content": prompt},
            ],
            temperature=0.2,
        )
        return response.choices[0].message.content or ""
