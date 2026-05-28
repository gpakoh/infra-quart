#!/usr/bin/env bash
set -euo pipefail

echo "=== Checking for leaked secrets ==="

errors=0

check_not_tracked() {
  local pattern="$1"
  local label="$2"
  if git ls-files --cached | grep -q "$pattern"; then
    echo "FAIL: $label ($pattern is tracked in git)"
    errors=$((errors + 1))
  else
    echo "OK: $label"
  fi
}

check_not_tracked '\.env$' ".env file"
check_not_tracked '\.env\.local$' ".env.local file"
check_not_tracked '\.env\.backup$' ".env.backup file"
check_not_tracked 'secrets/.*\.txt$' "secrets/*.txt files"
check_not_tracked 'secrets/.*\.token$' "secrets/*.token files"
check_not_tracked 'oauth_creds\.json' "oauth_creds.json files"
check_not_tracked 'id_ed25519' "SSH private keys"

if [ "$errors" -gt 0 ]; then
  echo "FAILED: $errors secret check(s) failed"
  exit 1
else
  echo "=== All secret checks passed ==="
fi
