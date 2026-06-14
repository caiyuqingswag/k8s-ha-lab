from app.schemas.alerts import IncidentRecord


class IncidentStore:
    """In-memory incident store for MVP.

    Replace this with PostgreSQL in the next phase.
    """

    def __init__(self) -> None:
        self._items: dict[str, IncidentRecord] = {}

    def add(self, incident: IncidentRecord) -> IncidentRecord:
        self._items[incident.id] = incident
        return incident

    def list(self) -> list[IncidentRecord]:
        return sorted(self._items.values(), key=lambda item: item.created_at, reverse=True)

    def get(self, incident_id: str) -> IncidentRecord | None:
        return self._items.get(incident_id)


incident_store = IncidentStore()
