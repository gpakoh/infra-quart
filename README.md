# infra-quart

Orchestration entry point for the quart ecosystem. Contains vendor services, submodule references to own-code services, and unified docker-compose with profiles.

## Principles

- No application code — only orchestration, configuration, and submodule references.
- No secrets in git — `.env.example` with placeholders only.
- Profile-based startup — start only what you need.

## Quick Start

```bash
cp .env.example .env
# edit .env with your secrets

make submodules

# Start core (postgres + redis + quart-core)
make up-core

# Start OpenCode Adapter
make up-opencode

# Check everything
make smoke
```

## Profiles

| Profile | Services | Command |
| -- | -- | -- |
| core | postgres, redis, rag-library-service, quart-core | `make up-core` |
| llm | ollama | `make up-llm` |
| embeddings | infinity | `make up-embeddings` |
| memory | zep | `make up-memory` |
| opencode | opencode-adapter | `make up-opencode` |
| monitoring | prometheus, grafana | `make up-monitoring` |
| federation | fds (nginx) | `make up-federation` |

## Submodules

| Path | Repository | Pinned |
| -- | -- | -- |
| services/opencode-adapter | opencode-adapter | v0.2.0 |
| services/quart-core | quart-core | v0.1.6 |
| services/rag-library-service | rag-library-service | v0.1.2 |
| services/quart-ollama_bot | quart-ollama_bot | v0.1.1 |

### Add a new submodule

```bash
git submodule add <url> services/<name>
cd services/<name> && git checkout <tag> && cd ../..
git add .gitmodules services/<name>
git commit -m "feat: add <name> submodule"
```

## Ports

| Service | Internal Port | Host Port | Notes |
| -- | -- | -- | -- |
| postgres | 5432 | 5432 | |
| redis | 6379 | — | internal only (host port closed) |
| quart-core | 5000 | 8000 | configurable via `QUART_CORE_PORT` |
| rag-library-service | 5001 | 8010 | configurable via `RAG_LIBRARY_PORT` |
| ollama | 11434 | 11434 | |
| infinity | 7997 | 7997 | |
| zep | 8000 | 8000 | |
| opencode-adapter | 8007 | 8008 | internal 8007, host 8008 |
| prometheus | 9090 | 9090 | |
| grafana | 3000 | 4999 | login: admin / admin |
| fds | 80 | 8081 | nginx file distribution |

## Structure

```
infra-quart/
├── docker-compose.yml         # Main compose with profiles
├── .env.example               # Environment template
├── Makefile                   # Convenience commands
├── scripts/
│   ├── smoke.sh               # Health checks + document CRUD flow
│   └── check-secrets.sh       # Verify no secrets on disk or tracked
├── secrets/.gitkeep
├── deploy/
│   ├── fds/nginx.conf
│   ├── monitoring/
│   │   ├── prometheus.yml
│   │   └── grafana-dashboard.json
│   └── zep/Dockerfile
    ├── services/
    ├── opencode-adapter/      # submodule, v0.2.0
    	├── quart-core/            # submodule, v0.1.6
    	└── rag-library-service/   # submodule, v0.1.1
```

## Database Image

The `postgres` service uses a custom image built from `services/database/Dockerfile`.

| Property | Value |
| -- | -- |
| Base image | `pgvector/pgvector:pg16` |
| Included extensions | pgvector v0.8.2, Apache AGE v1.6.0 |
| Release tag | `quart-database:latest` |
| Container name | `RAG_postgres` |
| Port | `5432:5432` |

Apache AGE v1.6.0 is compiled from source (`release/PG16/1.6.0` branch) at image build time. Init scripts at `/docker-entrypoint-initdb.d/` create `vector` and `age` extensions on first start.

**Limitation:** AGE compilation adds ~160–180 seconds to image build. Future improvements:
- Publish prebuilt `quart-database` image to a registry (CI or ghcr)
- Pin AGE source checksum for reproducible builds
- Use Docker build cache to skip rebuild when source is unchanged

## LightRAG Storage

LightRAG defaults to file-based storage. To use PostgreSQL-backed storage:

```bash
LIGHTRAG_STORAGE_BACKEND=postgres docker compose --profile core --profile memory up -d --build
```

This enables PGKVStorage, PGVectorStorage, PGGraphStorage, and PGDocStatusStorage with workspace isolation per bot.
