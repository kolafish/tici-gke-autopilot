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
kubectl cp "$ROOT_DIR/scripts/sample.sql" "$NAMESPACE/mysql-client-0:/tmp/sample.sql"

kubectl exec -n "$NAMESPACE" mysql-client-0 -- sh -c "mysql -h tidb-tidb.$NAMESPACE.svc -P 4000 -u root < /tmp/sample.sql"

echo "[sample-sql] Executed sample SQL"
