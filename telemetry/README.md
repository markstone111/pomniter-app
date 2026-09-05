# Telemetry — Pomniter Observability Stack

This directory contains all observability and monitoring configurations for the Pomniter platform.

## Directory Structure

`
telemetry/
├── collectors/      # OpenTelemetry Collector configurations
├── dashboards/      # Grafana dashboard JSON exports
├── alerts/          # Prometheus alerting rules
├── traces/          # Jaeger distributed tracing configs
├── logs/            # Loki log aggregation configs
└── README.md        # This file
`

## Stack Overview

| Component | Tool | Purpose |
|---|---|---|
| **Metrics** | Prometheus | Scrape and store time-series metrics |
| **Visualization** | Grafana | Dashboards, charts, alerting UI |
| **Tracing** | Jaeger + OpenTelemetry | Distributed request tracing across services |
| **Logging** | Loki (future) | Centralized log aggregation |
| **Alerting** | Prometheus Alertmanager | Alert routing and notifications |

## Key Metrics Tracked

### Application Metrics
- `pomniter_screenshots_processed_total` — Total screenshots processed
- `pomniter_ocr_duration_seconds` — OCR processing latency histogram
- `pomniter_embedding_duration_seconds` — Embedding generation latency
- `pomniter_search_duration_seconds` — Search query latency
- `pomniter_search_results_count` — Number of results per query

### Infrastructure Metrics
- Kafka consumer lag per topic
- PostgreSQL connection pool utilization
- Qdrant vector index size and query performance
- Redis cache hit/miss ratio
- Container resource usage (CPU, memory, network)

## Setup (Phase 2)

Telemetry infrastructure is introduced in Phase 2. During Phase 1, basic structured logging is used across all services.
