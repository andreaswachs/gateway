
.PHONY: setup
setup:
	@echo "Running interactive setup..."
	@./scripts/setup.sh

.PHONY: build
build:
	@npm run fetch-data
	@npm run build
	@docker build -t work/gateway .

.PHONY: run
run-dev:
	@docker run -p 5678:8080 work/gateway

.PHONY: down
down:
	docker-compose down

.PHONY: launch
launch: down build
	docker compose up -d

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make setup     - Run interactive setup wizard"
	@echo "  make build     - Build Docker image (fetches data and builds)"
	@echo "  make launch    - Stop, rebuild, and start the Docker container"
	@echo "  make run-dev   - Run the Docker container"
	@echo "  make down      - Stop Docker container"
