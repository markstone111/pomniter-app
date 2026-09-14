# Pomniter App — Project Context & Session Handover Document

> **Purpose**: This document preserves the complete architectural context, user decisions, progress history, and technical roadmap across development sessions.

---

## 🎯 Vision & Product Philosophy
- **Name**: **Pomniter** (*помнить* = "to remember")
- **Tagline**: *"Search screenshots the way you remember them."*
- **Positioning**: Open-source, local-first, platform-independent AI screenshot memory search engine (unlike generic, walled-garden screenshot apps from Apple, Samsung, etc.).
- **Development Pace**: Slow, deliberate, and bulletproof engineering. Quality, type safety, test coverage, and documentation over rushing.
- **Visual Aesthetic**: Neo-brutal design system matching the Pomniter website (thick solid borders, hard offset zero-blur shadows, Space Grotesk headings, JetBrains Mono code/OCR text, vibrant color accents: `#FFE156` yellow, `#00E5FF` cyan, `#FF6B9D` pink, `#4ADE80` green).

---

## 🔒 Key Engineering Principles & Standards
1. **Local-First Privacy**:
   - Screenshots and vector embeddings stay on-device by default.
   - Cloud sync and heavy backend processing are opt-in and privacy-respecting.
2. **Tech-Giant Infrastructure Standards**:
   - Dedicated `telemetry/` folder for Prometheus scraping, Grafana dashboards, and OpenTelemetry tracing.
   - Dedicated `tests/` directory with fixtures, integration, and E2E regression suites.
   - Enterprise streaming: Apache Kafka 3.7+ in KRaft mode (no Zookeeper).
3. **Monorepo Architecture (Melos)**:
   - `apps/mobile`: Flutter mobile app (Riverpod + GoRouter).
   - `packages/design-system`: Standalone neo-brutal UI library with 100% test coverage.
   - `packages/shared-models`: Pure Dart domain entities, zero runtime dependencies.
   - `packages/core-engine`: Repositories, use cases, OCR & Embedding engine contracts.
   - `services/`: Backend microservices (API Gateway, OCR, Embedding, Search).
   - `infra/`: Docker Compose, SQL migrations, topic scripts.

---

## 📦 Repositories
1. **Mobile App & Engine Monorepo**: [github.com/markstone111/pomniter-app](https://github.com/markstone111/pomniter-app)
   - License: Apache 2.0
   - Branch: `main`
2. **Landing Page Web App**: [github.com/markstone111/pomniter](https://github.com/markstone111/pomniter)
   - Tech: Next.js, Tailwind/Vanilla CSS

---

## ✅ Current Completion Status (Phase 1 Foundation)

### Packages & Tests:
- [x] **`packages/design-system`**:
  - Tokens: `NeoColors`, `NeoTypography`, `NeoBorders`, `NeoShadows`.
  - Theme: `NeoThemeData.light`, `NeoThemeData.dark`, `NeoTheme.toMaterialTheme`.
  - Widgets: `NeoButton`, `NeoCard`, `NeoBadge`, `NeoTextField`, `NeoAppBar`, `NeoScaffold`.
  - **Tests**: 10/10 passed (`flutter test`), 0 analyzer issues.
- [x] **`packages/shared-models`**:
  - Models: `Screenshot`, `TextBlock`, `BoundingBox`, `SearchResult`, `SearchQuery`, `User`.
  - Enums: `ScreenshotCategory`, `MatchType`.
  - **Tests**: 7/7 passed (`flutter test`), 0 analyzer issues.
- [x] **`packages/core-engine`**:
  - Interfaces: `ScreenshotRepository`, `SearchRepository`, `OcrEngine`, `EmbeddingEngine`, `AuthRepository`.
  - In-memory & mock implementations for reliable offline testability.
  - Phase 1.6 On-Device ONNX ML: `OnnxOcrEngine` (PP-OCRv4 detection & recognition), `OnnxClipEmbeddingEngine` (MobileCLIP-S0 384-dim), `ClipTokenizer` (BPE), `engine_exceptions.dart`.
  - Phase 1.7 ObjectBox Local Vector DB: `ScreenshotEntity` (with `@HnswIndex` 384-dim float vector), `TextBlockEntity`, `ObjectBoxScreenshotRepository`, `ObjectBoxSearchRepository`, `openObjectBoxStore`.
  - Use cases: `ProcessScreenshotUseCase`, `SearchScreenshotsUseCase`.
  - **Tests**: 14/14 passed (`flutter test`), 0 analyzer issues.
- [x] **`apps/mobile`**:
  - State: Flutter Riverpod 2.6.
  - Router: GoRouter 14.8 with `/init` onboarding route.
  - Screens: `HomeScreen`, `SearchScreen`, `GalleryScreen`, `ScreenshotDetailScreen`, `SettingsScreen`, `MlInitScreen`.
  - Services: `ModelDownloadManager` (CDN streaming with SHA-256 checksums and local caching).
  - Providers: ObjectBox & ONNX engine providers in `engine_providers.dart`.
  - **Tests**: 1/1 passed (`flutter test`), 0 analyzer issues.

### Infrastructure & Telemetry:
- [x] **`docker-compose.yml`**: PostgreSQL 16, Redis 7, MinIO S3, Kafka 3.7 KRaft, Prometheus, Grafana, API Gateway, OCR Service, Embedding Service, Search Service.
- [x] **SQL Schema**: `infra/docker/postgres/init.sql` (`users`, `screenshots`, `text_blocks`, `screenshot_tags`, `search_logs`).
- [x] **Kafka Topics**: `infra/scripts/create-kafka-topics.ps1` (`screenshot.uploaded`, `screenshot.ocr.completed`, `screenshot.embedding.completed`, `screenshot.indexed`).
- [x] **Telemetry Configs**: `telemetry/prometheus/prometheus.yml`, `telemetry/grafana/datasources/datasources.yaml`.
- [x] **E2E Infrastructure & Pipeline Tests**: `tests/integration/test_pipeline_e2e.py` (6/6 passed).

### Backend Microservices (Phase 1.8):
- [x] **`services/api-gateway`**: Fastify 4 + TypeScript (JWT auth, multipart upload, MinIO/local storage, Kafka producer, Prometheus `/metrics`). 6/6 tests passed (`vitest`).
- [x] **`services/ocr-service`**: FastAPI + PaddleOCR/ONNX engine (port 8001, text block extraction, Kafka consumer `screenshot.uploaded` -> producer `screenshot.ocr.completed`, Prometheus `/metrics`). 4/4 tests passed (`pytest`).
- [x] **`services/embedding-service`**: FastAPI + MobileCLIP-S0 (port 8002, 384-dimensional normalized vector embeddings, Kafka consumer `screenshot.ocr.completed` -> producer `screenshot.embedding.completed`, Prometheus `/metrics`). 5/5 tests passed (`pytest`).
- [x] **`services/search-service`**: FastAPI + Hybrid Search (port 8003, Reciprocal Rank Fusion lexical & semantic scoring, Kafka consumer `screenshot.embedding.completed` -> indexer -> producer `screenshot.indexed`, Prometheus `/metrics`). 5/5 tests passed (`pytest`).

---

## 🚀 Next Steps Roadmap (When Resuming)

1. **Cloud Sync & Mobile-Backend Integration (Phase 1.9)**:
   - Encrypted sync client in `apps/mobile` syncing local ObjectBox vectors to API Gateway.
   - Background screenshot auto-detection worker for Android (MediaStore / ContentObserver).
2. **First-Launch Privacy & Transparency Agreement**:
   - First-run acceptance modal explaining local-first guarantees and optional cloud backup.

