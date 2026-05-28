#!/usr/bin/env bash
set -euo pipefail

echo "=== Checking for leaked secrets ==="

errors=0

check_not_exists() {
  local label="$1"
  shift
  local find_args=("$@")

  local files
  files=$(find . -path "./.git" -prune -o \( "${find_args[@]}" \) -print 2>/dev/null | head -5 || true)
  if [ -n "$files" ]; then
    echo "FAIL: $label (file exists: $(echo "$files" | tr '\n' ' '))"
    errors=$((errors + 1))
    return
  fi

  echo "OK: $label"
}

check_not_exists ".env file"              -name ".env"
check_not_exists ".env.local file"         -name ".env.local"
check_not_exists ".env.backup file"        -name ".env.backup"
check_not_exists "secrets/*.txt files"     -path "*/secrets/*.txt"
check_not_exists "secrets/*.token files"   -path "*/secrets/*.token"
check_not_exists "oauth_creds.json files"  -name "oauth_creds.json"
check_not_exists "SSH private keys"        -name "id_ed25519*" ! -name "*.pub"

if [ "$errors" -gt 0 ]; then
  echo "FAILED: $errors secret check(s) failed"
  exit 1
else
  echo "=== All secret checks passed ==="
fi
