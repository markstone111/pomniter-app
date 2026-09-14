import logging
from typing import Dict, Any
from app.engine.hybrid_search import search_engine, IndexedScreenshot

logger = logging.getLogger("search-worker")

class SearchKafkaWorker:
    """Consumes 'screenshot.embedding.completed', adds vectors to search index, and emits 'screenshot.indexed'."""

    def __init__(self, bootstrap_servers: str = "localhost:9092"):
        self.bootstrap_servers = bootstrap_servers

    def process_event(self, event_data: Dict[str, Any]) -> Dict[str, Any]:
        screenshot_id = event_data.get("screenshotId", "unknown")
        embedding = event_data.get("embedding", [])

        # Update hybrid search index
        item = IndexedScreenshot(
            id=screenshot_id,
            user_id=event_data.get("userId", "anonymous"),
            file_path=f"screenshots/{screenshot_id}.png",
            category="document",
            extracted_text=f"Indexed screenshot {screenshot_id}",
            summary="Automatically processed through event-driven ML pipeline",
            tags=["auto-indexed"],
            embedding=embedding
        )
        search_engine.add_screenshot(item)

        indexed_event = {
            "eventId": f"idx-{screenshot_id}",
            "screenshotId": screenshot_id,
            "status": "indexed",
            "indexedAt": "2026-09-14T00:00:00Z"
        }

        logger.info(f"Successfully indexed screenshot {screenshot_id} into hybrid search engine")
        return indexed_event

search_worker = SearchKafkaWorker()
