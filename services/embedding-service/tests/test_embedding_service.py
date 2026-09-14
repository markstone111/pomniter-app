from fastapi.testclient import TestClient
import numpy as np
from app.main import app
from app.engine.clip_engine import VECTOR_DIMENSION
from app.worker.kafka_worker import embedding_worker

client = TestClient(app)

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["dimensions"] == 384
    assert data["model"] == "MobileCLIP-S0"

def test_metrics_endpoint():
    response = client.get("/metrics")
    assert response.status_code == 200
    assert b"pomniter_embedding_requests_total" in response.content

def test_text_embedding_generation():
    response = client.post(
        "/api/v1/embeddings/text",
        json={"text": "Starbucks iced oat latte receipt"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["dimension"] == 384
    vec = np.array(data["embedding"], dtype=np.float32)
    assert len(vec) == 384
    norm = np.linalg.norm(vec)
    assert 0.99 <= norm <= 1.01

def test_image_embedding_generation():
    response = client.post(
        "/api/v1/embeddings/image",
        json={"image_path_or_url": "screenshots/flight_ticket.png"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["dimension"] == 384

def test_kafka_worker_event():
    event = {
        "screenshotId": "sc-999",
        "extractedText": "INDIGO FLIGHT 6E-204 DELHI TO BANGALORE",
        "userId": "user-456"
    }
    result = embedding_worker.process_event(event)
    assert result["screenshotId"] == "sc-999"
    assert result["dimension"] == 384
    assert len(result["embedding"]) == 384
