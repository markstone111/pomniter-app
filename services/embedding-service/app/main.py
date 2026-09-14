from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Optional
from prometheus_client import make_asgi_app, Counter, Histogram
from app.engine.clip_engine import clip_engine, VECTOR_DIMENSION

app = FastAPI(
    title="Pomniter Embedding Service",
    description="Multimodal MobileCLIP-S0 vector embedding service (384 dimensions)",
    version="1.0.0"
)

# Prometheus metrics setup
embedding_requests_total = Counter(
    "pomniter_embedding_requests_total",
    "Total embedding extraction requests processed",
    ["modality", "status"]
)
embedding_duration_seconds = Histogram(
    "pomniter_embedding_duration_seconds",
    "Duration of embedding generation in seconds",
    ["modality"]
)

# Mount Prometheus /metrics
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

class TextEmbeddingRequest(BaseModel):
    text: str

class ImageEmbeddingRequest(BaseModel):
    image_path_or_url: str

class EmbeddingResponse(BaseModel):
    embedding: List[float]
    dimension: int
    model: str

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "pomniter-embedding-service",
        "version": "1.0.0",
        "model": "MobileCLIP-S0",
        "dimensions": VECTOR_DIMENSION
    }

@app.post("/api/v1/embeddings/text", response_model=EmbeddingResponse)
def generate_text_embedding(payload: TextEmbeddingRequest):
    with embedding_duration_seconds.labels(modality="text").time():
        vector = clip_engine.encode_text(payload.text)

    embedding_requests_total.labels(modality="text", status="success").inc()

    return EmbeddingResponse(
        embedding=vector,
        dimension=len(vector),
        model="MobileCLIP-S0"
    )

@app.post("/api/v1/embeddings/image", response_model=EmbeddingResponse)
def generate_image_embedding(payload: ImageEmbeddingRequest):
    with embedding_duration_seconds.labels(modality="image").time():
        vector = clip_engine.encode_image(payload.image_path_or_url)

    embedding_requests_total.labels(modality="image", status="success").inc()

    return EmbeddingResponse(
        embedding=vector,
        dimension=len(vector),
        model="MobileCLIP-S0"
    )
