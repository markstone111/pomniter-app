# Pomniter App — AI-Powered Screenshot Memory Engine

<p align="center">
  <strong>помнить (pomnit) = to remember</strong>
</p>

<p align="center">
  <em>Search screenshots the way you remember them.</em>
</p>

---

## What is Pomniter?

**Pomniter** is an open-source, local-first, AI-powered screenshot memory search engine. Unlike basic OCR tools or native gallery search, Pomniter uses **multimodal vision models** and **dense vector embeddings** to understand the *semantic meaning* of your screenshots — enabling natural language retrieval using fuzzy human memory.

> "Find that binary search overflow trick from LeetCode"  
> Pomniter understands this is not about the literal text, but about a programming concept.

### Key Differentiators

| Feature | Native Gallery | Pomniter |
|---|---|---|
| Search | Exact keyword match | Fuzzy semantic search |
| Code Understanding | None | Detects algorithms, languages, patterns |
| Organization | Manual folders/tags | Zero-effort auto-categorization |
| Privacy | Cloud-dependent | **Local-first**, works fully offline |
| Open Source | Closed | Apache 2.0 |

---

## Repository Structure

`
pomniter-app/
├── apps/mobile/              # Flutter app (Android + iOS)
├── services/                 # Backend microservices
│   ├── api-gateway/          #   Fastify — REST API + Auth
│   ├── ocr-service/          #   FastAPI — PaddleOCR processing
│   ├── embedding-service/    #   FastAPI — Vector embedding generation
│   ├── search-service/       #   FastAPI — Semantic search & retrieval
│   └── notification-service/ #   Fastify — Push notifications
├── packages/                 # Shared Flutter packages
│   ├── design-system/        #   Neo-brutal UI component library
│   ├── shared-models/        #   Cross-platform data contracts
│   └── core-engine/          #   Business logic & offline sync
├── infra/                    # Docker, Terraform, K8s, monitoring
├── ml/                       # ML model configs & evaluation
├── telemetry/                # Observability: collectors, dashboards, alerts
├── tests/                    # Integration, E2E, load tests, fixtures
├── docs/                     # ADRs, API specs, dev guides, changelog
└── scripts/                  # CI/CD and automation scripts
`

---

## Quick Start

### Prerequisites

- Flutter SDK (>= 3.47)
- Docker Desktop
- Node.js (>= 22.x)
- Python (>= 3.12)

### Development Setup

`ash
git clone https://github.com/markstone111/pomniter-app.git
cd pomniter-app
dart pub global activate melos
melos bootstrap
cd apps/mobile && flutter run
`

For detailed setup instructions, see `docs/development/SETUP.md`.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Mobile** | Flutter, Dart, Riverpod, ObjectBox |
| **On-Device ML** | ONNX Runtime, PaddleOCR-Lite, MobileCLIP |
| **Backend** | Fastify (TS), FastAPI (Python) |
| **Data** | PostgreSQL, Redis, Qdrant, Apache Kafka |
| **Infrastructure** | Docker, Nginx, Terraform, AWS |
| **Monitoring** | Prometheus, Grafana, OpenTelemetry |

---

## Documentation

- Architecture Decision Records — `docs/architecture/`
- API Documentation — `docs/api/`
- Development Setup — `docs/development/SETUP.md`
- Contributing — `docs/development/CONTRIBUTING.md`
- Changelog — `docs/changelog/CHANGELOG.md`
- Engineering Blog — `docs/blog/`

---

## License

This project is licensed under the Apache License 2.0.

---

## Author

**Nikunj Maheshwari**
- Website: https://www.nikunjmaheshwari.in
- GitHub: @markstone111
- LinkedIn: nikunjmaheshwari

---

Built with love and помнить
