#!/usr/bin/env bash
set -euo pipefail

echo "=== infra-quart smoke tests ==="

QUART_CORE_PORT="${QUART_CORE_PORT:-8000}"
OPENCODE_ADAPTER_PORT="${OPENCODE_ADAPTER_PORT:-8008}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"
INFINITY_PORT="${INFINITY_PORT:-7997}"

all_ok=true

check() {
  local name="$1"
  local url="$2"
  echo -n "$name: "
  if curl -sf "$url" &>/dev/null; then
    echo "OK"
  else
    echo "FAIL ($url)"
    all_ok=false
  fi
}

# Core services
check "Postgres"    "http://localhost:5432"
check "Redis"       "tcp-health"  # skip redis — no HTTP

# Quart core
if docker ps -q --filter "name=RAG_quart_core" | grep -q .; then
  check "Quart Core" "http://localhost:${QUART_CORE_PORT}/health"
fi

# OpenCode adapter
if docker ps -q --filter "name=RAG_opencode-adapter" | grep -q .; then
  check "OpenCode Adapter" "http://localhost:${OPENCODE_ADAPTER_PORT}/health"
fi

# Ollama
if docker ps -q --filter "name=RAG_ollama" | grep -q .; then
  echo -n "Ollama: "
  if curl -sf "http://localhost:${OLLAMA_PORT}" &>/dev/null; then
    echo "OK"
  else
    echo "FAIL"
    all_ok=false
  fi
fi

# Infinity
if docker ps -q --filter "name=RAG_infinity" | grep -q .; then
  check "Infinity" "http://localhost:${INFINITY_PORT}/health"
fi

if $all_ok; then
  echo "=== All smoke tests passed ==="
else
  echo "=== Some smoke tests FAILED ==="
  exit 1
fi
