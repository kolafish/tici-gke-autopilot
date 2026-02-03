#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

if [[ ! -f "$ROOT_DIR/config.env" ]]; then
  echo "[sample-sql] Missing config.env. Copy config.env.example and fill it in." >&2
  exit 1
fi
# shellcheck disable=SC1091
source "$ROOT_DIR/config.env"

NAMESPACE=${NAMESPACE:-tidb-fts}
SLEEP_AFTER_INSERT=${SLEEP_AFTER_INSERT:-5}
TABLE_SUFFIX=$(date +"%Y%m%d%H%M%S")
TABLE_NAME="t1_${TABLE_SUFFIX}"
SQL_TMP=$(mktemp "${TMPDIR:-/tmp}/tici-sample.XXXXXX.sql")
QUERY_TMP=$(mktemp "${TMPDIR:-/tmp}/tici-query.XXXXXX.sql")

cleanup() {
  rm -f "$SQL_TMP" "$QUERY_TMP"
}
trap cleanup EXIT

render_sql() {
  local input="$1"
  local output="$2"
  sed "s/__TABLE_NAME__/${TABLE_NAME}/g" "$input" > "$output"
}

print_sql_steps() {
  local file="$1"
  awk 'BEGIN{RS=";"; ORS="";} {gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", $0); if(length($0)>0){print "[sample-sql] SQL: " $0 ";\n"}}' "$file"
}

kubectl rollout status -n "$NAMESPACE" statefulset/mysql-client --timeout=10m
kubectl rollout status -n "$NAMESPACE" statefulset/tidb-tidb --timeout=20m

render_sql "$ROOT_DIR/scripts/sample.sql" "$SQL_TMP"
render_sql "$ROOT_DIR/scripts/sample-query.sql" "$QUERY_TMP"

echo "[sample-sql] Using table name: $TABLE_NAME"
print_sql_steps "$SQL_TMP"

kubectl cp "$SQL_TMP" "$NAMESPACE/mysql-client-0:/tmp/sample.sql"
kubectl cp "$QUERY_TMP" "$NAMESPACE/mysql-client-0:/tmp/sample-query.sql"

for _ in {1..30}; do
  if kubectl exec -n "$NAMESPACE" mysql-client-0 -- sh -c "mysql --connect-timeout=5 -h tidb-tidb.$NAMESPACE.svc -P 4000 -u root -e 'SELECT 1'" >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

kubectl exec -n "$NAMESPACE" mysql-client-0 -- sh -c "mysql -h tidb-tidb.$NAMESPACE.svc -P 4000 -u root < /tmp/sample.sql"

echo "[sample-sql] Sleeping ${SLEEP_AFTER_INSERT}s after inserts..."
sleep "$SLEEP_AFTER_INSERT"

print_sql_steps "$QUERY_TMP"
while true; do
  query_output=$(kubectl exec -n "$NAMESPACE" mysql-client-0 -- sh -c "mysql -N -B -h tidb-tidb.$NAMESPACE.svc -P 4000 -u root < /tmp/sample-query.sql" 2>&1) && query_exit=0 || query_exit=$?
  if [[ "$query_exit" -ne 0 ]]; then
    echo "[sample-sql] Query failed, retrying in 1s..."
    printf '%s\n' "$query_output" >&2
    sleep 1
    continue
  fi
  if [[ -n "${query_output}" ]]; then
    printf '%s\n' "$query_output"
    break
  fi
  echo "[sample-sql] Empty result, retrying in 1s..."
  sleep 1
done

echo "[sample-sql] Executed sample SQL"
