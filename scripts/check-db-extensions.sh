#!/usr/bin/env bash
set -euo pipefail

# Check that PostgreSQL extensions (vector + AGE) are installed and working.
# Usage: make check-db-extensions  (or bash scripts/check-db-extensions.sh)
#
# Expects:
#   - RAG_postgres container running
#   - psql installed in the container

CONTAINER="${CONTAINER:-RAG_postgres}"
DB_USER="${POSTGRES_USER:-raguser}"
DB_NAME="${POSTGRES_DB:-rag_vectordb}"
PSQL="docker exec $CONTAINER psql -U $DB_USER -d $DB_NAME -tA"

echo "=== Database Extension Checks ==="
echo "Container: $CONTAINER"
echo "Database:  $DB_NAME"
echo ""

# 1. vector extension
echo "1. Checking vector extension..."
VECTOR_OK=$($PSQL -c "SELECT count(*) FROM pg_extension WHERE extname = 'vector';" 2>/dev/null | sed -n '1p' | tr -d ' ')
if [ "$VECTOR_OK" = "1" ]; then
    echo "   ✓ vector extension is installed"
else
    echo "   ✗ vector extension NOT found"
    exit 1
fi

# 2. age extension
echo "2. Checking age extension..."
AGE_OK=$($PSQL -c "SELECT count(*) FROM pg_extension WHERE extname = 'age';" 2>/dev/null | sed -n '1p' | tr -d ' ')
if [ "$AGE_OK" = "1" ]; then
    echo "   ✓ age extension is installed"
else
    echo "   ✗ age extension NOT found"
    exit 1
fi

# 3. LOAD 'age'
echo "3. Checking LOAD 'age'..."
if $PSQL -c "LOAD 'age';" 2>/dev/null; then
    echo "   ✓ LOAD 'age' succeeded"
else
    echo "   ✗ LOAD 'age' failed"
    exit 1
fi

# 4. SET search_path (ag_catalog)
echo "4. Checking SET search_path = ag_catalog..."
if $PSQL -c "SET search_path = ag_catalog, \"\$user\", public;" 2>/dev/null; then
    echo "   ✓ search_path includes ag_catalog"
else
    echo "   ✗ SET search_path failed"
    exit 1
fi

# 5. Simple AGE query (create_graph + drop_graph)
echo "5. Checking basic AGE graph operations..."
if $PSQL -c "LOAD 'age'; SET search_path = ag_catalog, public; SELECT * FROM drop_graph('test_check', true); SELECT * FROM create_graph('test_check'); SELECT * FROM drop_graph('test_check', true);" >/dev/null 2>/dev/null; then
    echo "   ✓ AGE create_graph and drop_graph work"
else
    echo "   ✗ AGE graph operations failed"
    exit 1
fi

echo ""
echo "=== All checks passed ==="
