# Tests — Pomniter Testing Infrastructure

This directory contains all testing resources that span multiple services and packages.

> **Philosophy**: Nothing ships without tests. Every PR must pass CI. Every critical path has integration tests.

## Directory Structure

`
tests/
├── unit/            # Cross-service unit test utilities and helpers
├── integration/     # Multi-service integration tests
├── e2e/             # End-to-end pipeline tests (capture -> search)
├── load/            # k6 load testing scripts
├── fixtures/        # Shared test data (sample screenshots, OCR outputs)
├── mocks/           # Mock services for isolated testing
└── README.md        # This file
`

## Testing Layers

### 1. Unit Tests (per package/service)
Each Flutter package and backend service has its own unit tests:
- `packages/design-system/test/` — Widget tests for UI components
- `packages/core-engine/test/` — Business logic tests
- `services/*/tests/` — Service-specific unit tests

### 2. Integration Tests (this directory)
Tests that verify communication between multiple services:
- API Gateway -> OCR Service pipeline
- Kafka message flow: publish -> consume -> process
- Database migrations and queries
- Vector search accuracy benchmarks

### 3. End-to-End Tests (this directory)
Full pipeline tests running in Docker Compose:
- Screenshot upload -> OCR -> Embedding -> Index -> Search
- Auth flow: register -> login -> use -> logout
- Offline mode: local capture -> local search

### 4. Load Tests (this directory)
k6 scripts for performance testing:
- Search endpoint throughput
- Concurrent image upload handling
- Vector search latency under load

## Test Fixtures

The `fixtures/` directory contains sample data used across all test types:
- Sample screenshot images (code, receipts, notes, etc.)
- Expected OCR output for each sample
- Expected embedding vectors for validation
- Mock API responses

## Running Tests

`ash
# Run all Flutter tests
make test-flutter

# Run all backend tests
make test-backend

# Run integration tests (requires Docker)
make test-integration

# Run load tests (requires k6)
make test-load

# Run everything
make test
`

## CI/CD Integration

All tests run automatically via GitHub Actions on every PR:
1. Flutter lint + analyze + test
2. Backend lint + test
3. Docker build verification
4. Integration tests (on main branch merges)
