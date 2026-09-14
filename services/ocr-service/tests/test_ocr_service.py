from fastapi.testclient import TestClient
from app.main import app
from app.worker.kafka_worker import ocr_worker

client = TestClient(app)

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["service"] == "pomniter-ocr-service"

def test_metrics_endpoint():
    response = client.get("/metrics")
    assert response.status_code == 200
    assert b"pomniter_ocr_requests_total" in response.content

def test_ocr_process_endpoint():
    response = client.post(
        "/api/v1/ocr/process",
        json={
            "screenshot_id": "sc-test-101",
            "raw_text_hint": "Starbucks Coffee\nIced Latte $5.75\nTotal $5.75"
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["screenshot_id"] == "sc-test-101"
    assert "Starbucks Coffee" in data["extracted_text"]
    assert len(data["text_blocks"]) >= 3
    assert data["text_blocks"][0]["confidence"] > 0.9

def test_kafka_worker_event_processing():
    event = {
        "screenshotId": "sc-event-404",
        "filePath": "screenshots/receipt.png",
        "userId": "user-123"
    }
    result = ocr_worker.process_event(event)
    assert result["screenshotId"] == "sc-event-404"
    assert "extractedText" in result
    assert len(result["textBlocks"]) > 0
