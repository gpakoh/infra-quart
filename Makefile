.PHONY: help up-core up-llm up-embeddings up-memory up-opencode up-monitoring up-federation up-all down smoke check-secrets

help:
	@echo "infra-quart — orchestration entry point"
	@echo ""
	@echo "Setup:"
	@echo "  cp .env.example .env        Create environment file"
	@echo "  git submodule update --init --recursive  Fetch all submodules"
	@echo ""
	@echo "Start services (profiles):"
	@echo "  up-core        Start PostgreSQL + Redis"
	@echo "  up-llm         Start Ollama"
	@echo "  up-embeddings  Start Infinity"
	@echo "  up-memory      Start Zep"
	@echo "  up-opencode    Start OpenCode Adapter"
	@echo "  up-monitoring  Start Prometheus + Grafana"
	@echo "  up-federation  Start FDS (file distribution)"
	@echo "  up-all         Start everything"
	@echo ""
	@echo "Management:"
	@echo "  down           Stop all services"
	@echo "  smoke          Run smoke tests"
	@echo "  check-secrets  Verify no secrets leaked into repo"

up-core:
	docker compose --profile core up -d

up-llm:
	docker compose --profile llm up -d

up-embeddings:
	docker compose --profile embeddings up -d

up-memory:
	docker compose --profile core --profile memory up -d

up-opencode:
	docker compose --profile opencode up -d

up-monitoring:
	docker compose --profile monitoring up -d

up-federation:
	docker compose --profile federation up -d

up-all:
	docker compose --profile core --profile llm --profile embeddings --profile memory --profile opencode --profile monitoring --profile federation up -d

down:
	docker compose down

smoke:
	./scripts/smoke.sh

check-secrets:
	./scripts/check-secrets.sh
