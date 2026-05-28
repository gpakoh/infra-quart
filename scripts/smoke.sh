#!/usr/bin/env bash
set -euo pipefail

echo "=== infra-quart smoke tests ==="

# Check postgres
echo -n "Postgres: "
if docker exec RAG_postgres pg_isready -U raguser -d rag_vectordb &>/dev/null; then
  echo "OK"
else
  echo "FAIL"
  exit 1
fi

# Check redis
echo -n "Redis: "
if docker exec RAG_redis redis-cli ping | grep -q PONG; then
  echo "OK"
else
  echo "FAIL"
  exit 1
fi

# Check ollama (if running)
if docker ps -q --filter "name=RAG_ollama" | grep -q .; then
  echo -n "Ollama: "
  if curl -sf http://localhost:11434 &>/dev/null; then
    echo "OK"
  else
    echo "FAIL"
    exit 1
  fi
fi

# Check infinity (if running)
if docker ps -q --filter "name=RAG_infinity" | grep -q .; then
  echo -n "Infinity: "
  if curl -sf http://localhost:7997/health &>/dev/null; then
    echo "OK"
  else
    echo "FAIL"
    exit 1
  fi
fi

# Check opencode-adapter (if running)
if docker ps -q --filter "name=RAG_opencode-adapter" | grep -q .; then
  echo -n "OpenCode Adapter: "
  if curl -sf http://localhost:8007/health &>/dev/null; then
    echo "OK"
  else
    echo "FAIL"
    exit 1
  fi
fi

echo "=== All smoke tests passed ==="
