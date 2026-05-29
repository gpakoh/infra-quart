#!/usr/bin/env bash
set -euo pipefail

echo "=== infra-quart smoke tests ==="

QUART_CORE_PORT="${QUART_CORE_PORT:-8000}"
OPENCODE_ADAPTER_PORT="${OPENCODE_ADAPTER_PORT:-8008}"
RAG_LIBRARY_PORT="${RAG_LIBRARY_PORT:-8010}"
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

# RAG Library Service
if docker ps -q --filter "name=RAG_rag_library" | grep -q .; then
  check "RAG Library" "http://localhost:${RAG_LIBRARY_PORT}/health"
fi

# Document CRUD flow (requires rag-library-service)
crud_flow() {
  local base="$1"
  local bot_id="${2:-smoke-bot}"
  local doc_id="${3:-smoke/test.txt}"
  local doc_content="${4:-Hello from smoke test}"

  echo "--- Document CRUD flow (bot=$bot_id, doc=$doc_id) ---"

  # Create
  echo -n "  CREATE: "
  resp=$(curl -sf -X POST "$base/v1/documents" \
    -H "Content-Type: application/json" \
    -d "{\"document_id\":\"$doc_id\",\"bot_id\":\"$bot_id\",\"content\":\"$doc_content\"}" 2>&1) && echo "OK" || { echo "FAIL"; return 1; }

  # List
  echo -n "  LIST:   "
  curl -sf "$base/v1/documents?bot_id=$bot_id" &>/dev/null && echo "OK" || { echo "FAIL"; return 1; }

  # Get
  echo -n "  GET:    "
  curl -sf "$base/v1/documents/$doc_id?bot_id=$bot_id" &>/dev/null && echo "OK" || { echo "FAIL"; return 1; }

  # Delete
  echo -n "  DELETE: "
  curl -sf -X DELETE "$base/v1/documents/$doc_id?bot_id=$bot_id" &>/dev/null && echo "OK" || { echo "FAIL"; return 1; }

  # Verify 404 after delete
  echo -n "  VERIFY 404: "
  if curl -sf "$base/v1/documents/$doc_id?bot_id=$bot_id" &>/dev/null; then
    echo "FAIL (still exists)"
    return 1
  else
    echo "OK (deleted)"
  fi

  echo "--- Document CRUD flow passed ---"
}

# RAG Library — CRUD
if docker ps -q --filter "name=RAG_rag_library" | grep -q .; then
  if crud_flow "http://localhost:${RAG_LIBRARY_PORT}"; then
    :
  else
    all_ok=false
  fi
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
