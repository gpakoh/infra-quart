.PHONY: help submodules check-secrets config build-core up-core up-llm up-embeddings up-memory up-opencode up-monitoring up-federation up-all smoke logs down clean

help:
	@echo "infra-quart — orchestration entry point"
	@echo ""
	@echo "Setup:"
	@echo "  submodules     Fetch all submodules"
	@echo "  config         Validate docker-compose config"
	@echo "  check-secrets  Verify no secrets leaked into repo"
	@echo ""
	@echo "Build:"
	@echo "  build-core     Build quart-core image"
	@echo "  build-opencode Build opencode-adapter image"
	@echo ""
	@echo "Start services (profiles):"
	@echo "  up-core        Start postgres + redis + quart-core"
	@echo "  up-llm         Start Ollama"
	@echo "  up-embeddings  Start Infinity"
	@echo "  up-memory      Start Zep (requires up-core)"
	@echo "  up-opencode    Start OpenCode Adapter"
	@echo "  up-monitoring  Start Prometheus + Grafana"
	@echo "  up-federation  Start FDS (file distribution)"
	@echo "  up-all         Start everything"
	@echo ""
	@echo "Management:"
	@echo "  down           Stop all services"
	@echo "  clean          Stop + remove volumes"
	@echo "  smoke          Run smoke tests"
	@echo "  logs           Tail logs"

submodules:
	git submodule update --init --recursive

check-secrets:
	bash scripts/check-secrets.sh

config:
	docker compose config

build-core:
	docker compose --profile core build quart-core

build-opencode:
	docker compose --profile opencode build opencode-adapter

up-core:
	docker compose --profile core up -d --build

up-llm:
	docker compose --profile llm up -d

up-embeddings:
	docker compose --profile embeddings up -d

up-memory:
	docker compose --profile core --profile memory up -d

up-opencode:
	docker compose --profile opencode up -d --build

up-monitoring:
	docker compose --profile monitoring up -d

up-federation:
	docker compose --profile federation up -d

up-all:
	docker compose --profile core --profile llm --profile embeddings --profile memory --profile opencode --profile monitoring --profile federation up -d --build

down:
	docker compose down

clean:
	docker compose down -v

smoke:
	bash scripts/smoke.sh

logs:
	docker compose logs -f --tail=200
