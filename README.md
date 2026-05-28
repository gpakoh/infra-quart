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
| core | postgres, redis, quart-core | `make up-core` |
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
| services/quart-core | quart-core | v0.1.2 |

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
│   ├── smoke.sh               # Health checks
│   └── check-secrets.sh       # Verify no secrets on disk or tracked
├── secrets/.gitkeep
├── deploy/
│   ├── fds/nginx.conf
│   ├── monitoring/
│   │   ├── prometheus.yml
│   │   └── grafana-dashboard.json
│   └── zep/Dockerfile
└── services/
    ├── opencode-adapter/      # submodule, v0.2.0
    └── quart-core/            # submodule, v0.1.2
```
