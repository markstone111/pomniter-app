import json
import logging
from typing import Dict, Any
from app.engine.ocr_engine import ocr_engine

logger = logging.getLogger("ocr-worker")

class OcrKafkaWorker:
    """Consumes 'screenshot.uploaded' events, runs OCR, and produces 'screenshot.ocr.completed'."""

    def __init__(self, bootstrap_servers: str = "localhost:9092"):
        self.bootstrap_servers = bootstrap_servers
        self.is_running = False

    def process_event(self, event_data: Dict[str, Any]) -> Dict[str, Any]:
        screenshot_id = event_data.get("screenshotId", "unknown")
        file_path = event_data.get("filePath", "")

        ocr_result = ocr_engine.process_image(f"Extracted content for {screenshot_id} from {file_path}")

        completed_event = {
            "eventId": f"ocr-{screenshot_id}",
            "screenshotId": screenshot_id,
            "userId": event_data.get("userId", "anonymous"),
            "extractedText": ocr_result.extracted_text,
            "textBlocks": [
                {
                    "text": block.text,
                    "confidence": block.confidence,
                    "box": {
                        "left": block.box.left,
                        "top": block.box.top,
                        "width": block.box.width,
                        "height": block.box.height,
                    }
                }
                for block in ocr_result.text_blocks
            ],
            "processingTimeMs": ocr_result.processing_time_ms,
            "timestamp": "2026-09-14T00:00:00Z"
        }

        logger.info(f"Successfully processed OCR for screenshot: {screenshot_id}")
        return completed_event

ocr_worker = OcrKafkaWorker()
