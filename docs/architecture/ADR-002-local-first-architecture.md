# ADR-002: Local-First Architecture

## Status
**Accepted** — 2026-09-05

## Context
Pomniter processes personal screenshots containing sensitive data: bank statements, private conversations, medical records, proprietary code, and personal notes. Users must trust that their data remains private.

Additionally, users should be able to search their screenshots without internet connectivity — on flights, in remote areas, or in network-restricted environments.

## Decision
We adopt a **local-first architecture** with optional cloud sync:

### Tier 1: Fully Offline (Default)
- On-device OCR via ONNX Runtime + PaddleOCR-Lite
- On-device embeddings via ONNX Runtime + MobileCLIP (quantized)
- Local vector index via ObjectBox HNSW
- All search and retrieval happens on-device
- Zero network calls required for core functionality

### Tier 2: Cloud-Enhanced (Opt-in)
- When online, background sync sends images to server
- Server runs higher-quality models (full CLIP, Qwen3-VL)
- Enhanced embeddings are synced back to device
- User explicitly opts into cloud processing

### Data Flow
1. Screenshot captured -> Processed locally (Tier 1)
2. User searches -> Local vector search returns results instantly
3. (Optional) Background sync -> Server re-processes with better models
4. Enhanced embeddings replace local ones silently

## Consequences
- **Positive**: Complete privacy by default, works offline, no API costs for users
- **Negative**: On-device models are less accurate than server models; larger initial download
- **Mitigation**: Dual-engine approach gives best of both worlds; models downloaded on-demand
