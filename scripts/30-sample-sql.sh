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

kubectl rollout status -n "$NAMESPACE" statefulset/mysql-client --timeout=10m
kubectl rollout status -n "$NAMESPACE" statefulset/tidb-tidb --timeout=20m
kubectl cp "$ROOT_DIR/scripts/sample.sql" "$NAMESPACE/mysql-client-0:/tmp/sample.sql"
kubectl cp "$ROOT_DIR/scripts/sample-query.sql" "$NAMESPACE/mysql-client-0:/tmp/sample-query.sql"

for _ in {1..30}; do
  if kubectl exec -n "$NAMESPACE" mysql-client-0 -- sh -c "mysql --connect-timeout=5 -h tidb-tidb.$NAMESPACE.svc -P 4000 -u root -e 'SELECT 1'" >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

kubectl exec -n "$NAMESPACE" mysql-client-0 -- sh -c "mysql -h tidb-tidb.$NAMESPACE.svc -P 4000 -u root < /tmp/sample.sql"

query_ok=0
for _ in {1..30}; do
  if kubectl exec -n "$NAMESPACE" mysql-client-0 -- sh -c "mysql -h tidb-tidb.$NAMESPACE.svc -P 4000 -u root < /tmp/sample-query.sql"; then
    query_ok=1
    break
  fi
  sleep 5
done

if [[ "$query_ok" -ne 1 ]]; then
  echo "[sample-sql] Timed out waiting for TiCI FTS index to be ready." >&2
  exit 1
fi

echo "[sample-sql] Executed sample SQL"
