from fastapi.testclient import TestClient
from app.main import app
from app.worker.kafka_worker import search_worker

client = TestClient(app)

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["engine"] == "Hybrid-RRF"

def test_metrics_endpoint():
    response = client.get("/metrics")
    assert response.status_code == 200
    assert b"pomniter_search_requests_total" in response.content

def test_search_receipt_keyword():
    response = client.post(
        "/api/v1/search",
        json={"query": "Starbucks"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 1
    assert any(h["id"] == "sc-101" for h in data["results"])

def test_search_with_category_filter():
    response = client.post(
        "/api/v1/search",
        json={"query": "Docker", "category": "meme"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 1
    assert data["results"][0]["category"] == "meme"

def test_kafka_worker_indexing():
    event = {
        "screenshotId": "sc-live-100",
        "userId": "user-888",
        "embedding": [0.05] * 384
    }
    result = search_worker.process_event(event)
    assert result["screenshotId"] == "sc-live-100"
    assert result["status"] == "indexed"
