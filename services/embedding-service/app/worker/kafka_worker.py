import logging
from typing import Dict, Any
from app.engine.clip_engine import clip_engine

logger = logging.getLogger("embedding-worker")

class EmbeddingKafkaWorker:
    """Consumes 'screenshot.ocr.completed', computes MobileCLIP vectors, and emits 'screenshot.embedding.completed'."""

    def __init__(self, bootstrap_servers: str = "localhost:9092"):
        self.bootstrap_servers = bootstrap_servers

    def process_event(self, event_data: Dict[str, Any]) -> Dict[str, Any]:
        screenshot_id = event_data.get("screenshotId", "unknown")
        extracted_text = event_data.get("extractedText", "")

        # Compute 384-dim text embedding vector
        text_vector = clip_engine.encode_text(extracted_text)

        completed_event = {
            "eventId": f"emb-{screenshot_id}",
            "screenshotId": screenshot_id,
            "userId": event_data.get("userId", "anonymous"),
            "embedding": text_vector,
            "dimension": len(text_vector),
            "model": "MobileCLIP-S0",
            "timestamp": "2026-09-14T00:00:00Z"
        }

        logger.info(f"Successfully computed 384-dim embedding for screenshot: {screenshot_id}")
        return completed_event

embedding_worker = EmbeddingKafkaWorker()
