from fastapi import FastAPI
from pydantic import BaseModel
from typing import Optional, List
from prometheus_client import make_asgi_app, Counter, Histogram
from app.engine.ocr_engine import ocr_engine

app = FastAPI(
    title="Pomniter OCR Service",
    description="High-performance text detection and recognition service (PaddleOCR)",
    version="1.0.0"
)

# Prometheus metrics setup
ocr_requests_total = Counter(
    "pomniter_ocr_requests_total",
    "Total OCR extraction requests processed",
    ["status"]
)
ocr_duration_seconds = Histogram(
    "pomniter_ocr_duration_seconds",
    "Duration of OCR processing in seconds"
)

# Mount Prometheus /metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

class OcrProcessRequest(BaseModel):
    screenshot_id: str
    image_path: Optional[str] = None
    raw_text_hint: Optional[str] = None

class BoundingBoxModel(BaseModel):
    left: float
    top: float
    width: float
    height: float

class TextBlockModel(BaseModel):
    text: str
    confidence: float
    box: BoundingBoxModel

class OcrProcessResponse(BaseModel):
    screenshot_id: str
    extracted_text: str
    text_blocks: List[TextBlockModel]
    processing_time_ms: float

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "pomniter-ocr-service",
        "version": "1.0.0",
        "model": "PaddleOCR-Lite"
    }

@app.post("/api/v1/ocr/process", response_model=OcrProcessResponse)
def process_ocr(payload: OcrProcessRequest):
    input_content = payload.raw_text_hint or payload.image_path or payload.screenshot_id
    with ocr_duration_seconds.time():
        result = ocr_engine.process_image(input_content)

    ocr_requests_total.labels(status="success").inc()

    return OcrProcessResponse(
        screenshot_id=payload.screenshot_id,
        extracted_text=result.extracted_text,
        text_blocks=[
            TextBlockModel(
                text=b.text,
                confidence=b.confidence,
                box=BoundingBoxModel(
                    left=b.box.left,
                    top=b.box.top,
                    width=b.box.width,
                    height=b.box.height
                )
            )
            for b in result.text_blocks
        ],
        processing_time_ms=result.processing_time_ms
    )
