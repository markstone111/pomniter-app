from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Optional
from prometheus_client import make_asgi_app, Counter, Histogram
from app.engine.hybrid_search import search_engine

app = FastAPI(
    title="Pomniter Search Service",
    description="Hybrid lexical (BM25) and semantic vector search service",
    version="1.0.0"
)

# Prometheus metrics setup
search_requests_total = Counter(
    "pomniter_search_requests_total",
    "Total search queries processed",
    ["status"]
)
search_latency_seconds = Histogram(
    "pomniter_search_latency_seconds",
    "Latency of search execution in seconds"
)

# Mount Prometheus /metrics
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

class SearchRequest(BaseModel):
    query: str
    category: Optional[str] = None
    query_vector: Optional[List[float]] = None
    limit: Optional[int] = 30

class SearchHitResponse(BaseModel):
    id: str
    category: str
    file_path: str
    summary: str
    extracted_text: str
    score: float
    match_type: str

class SearchResponse(BaseModel):
    query: str
    total: int
    results: List[SearchHitResponse]

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "pomniter-search-service",
        "version": "1.0.0",
        "engine": "Hybrid-RRF"
    }

@app.post("/api/v1/search", response_model=SearchResponse)
def execute_search(payload: SearchRequest):
    with search_latency_seconds.time():
        hits = search_engine.search(
            query=payload.query,
            category=payload.category,
            query_vector=payload.query_vector,
            limit=payload.limit or 30
        )

    search_requests_total.labels(status="success").inc()

    return SearchResponse(
        query=payload.query,
        total=len(hits),
        results=[
            SearchHitResponse(
                id=h.screenshot.id,
                category=h.screenshot.category,
                file_path=h.screenshot.file_path,
                summary=h.screenshot.summary,
                extracted_text=h.screenshot.extracted_text,
                score=h.score,
                match_type=h.match_type
            )
            for h in hits
        ]
    )
