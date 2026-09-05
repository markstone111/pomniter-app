# =============================================================================
# Pomniter App — Makefile
# Convenience commands for development, testing, and deployment
# =============================================================================

.PHONY: help setup up down logs test lint clean

# Default target
help: ## Show this help
	@echo "Pomniter App — Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*'  | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", 1, 2}'

# ---------- Setup ----------
setup: ## Initial project setup (install all dependencies)
	dart pub global activate melos
	melos bootstrap
	cd services/api-gateway && npm install
	cd services/notification-service && npm install
	cd services/ocr-service && pip install -r requirements.txt
	cd services/embedding-service && pip install -r requirements.txt
	cd services/search-service && pip install -r requirements.txt

# ---------- Docker ----------
up: ## Start all backend services (Docker Compose)
	docker compose -f infra/docker-compose.yml up -d

down: ## Stop all backend services
	docker compose -f infra/docker-compose.yml down

logs: ## Tail logs from all services
	docker compose -f infra/docker-compose.yml logs -f

rebuild: ## Rebuild and restart all services
	docker compose -f infra/docker-compose.yml up -d --build

# ---------- Flutter ----------
app: ## Run the Flutter mobile app
	cd apps/mobile && flutter run

app-build-apk: ## Build Android APK
	cd apps/mobile && flutter build apk --release

app-build-ios: ## Build iOS (requires macOS)
	cd apps/mobile && flutter build ios --release

# ---------- Testing ----------
test: ## Run all tests
	melos run test
	cd services/api-gateway && npm test
	cd services/ocr-service && pytest
	cd services/embedding-service && pytest
	cd services/search-service && pytest

test-flutter: ## Run Flutter tests only
	melos run test

test-backend: ## Run backend tests only
	cd services/api-gateway && npm test
	cd services/ocr-service && pytest

test-integration: ## Run integration tests
	cd tests/integration && ./run.sh

test-load: ## Run load tests
	cd tests/load && k6 run load_test.js

# ---------- Code Quality ----------
lint: ## Lint all code
	melos run analyze
	cd services/api-gateway && npm run lint

format: ## Format all code
	melos run format

# ---------- Cleanup ----------
clean: ## Clean all build artifacts
	melos run clean
	docker compose -f infra/docker-compose.yml down -v --rmi local

# ---------- Documentation ----------
docs-serve: ## Serve documentation locally
	cd docs && python -m http.server 8080
