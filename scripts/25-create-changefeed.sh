#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SECRETS_ENV="$ROOT_DIR/.secrets.env"

if [[ ! -f "$ROOT_DIR/config.env" ]]; then
  echo "[changefeed] Missing config.env. Copy config.env.example and fill it in." >&2
  exit 1
fi
# shellcheck disable=SC1091
source "$ROOT_DIR/config.env"
if [[ -f "$SECRETS_ENV" ]]; then
  # shellcheck disable=SC1091
  source "$SECRETS_ENV"
fi

NAMESPACE=${NAMESPACE:-tidb-fts}
KEYSPACE_NAME=${KEYSPACE_NAME:-default}
: "${S3_BUCKET:?Missing S3_BUCKET}"
: "${S3_ACCESS_KEY:?Missing S3_ACCESS_KEY}"
: "${S3_SECRET_KEY:?Missing S3_SECRET_KEY}"
: "${S3_ENDPOINT:?Missing S3_ENDPOINT}"

CHANGEFEED_ID=${CHANGEFEED_ID:-tici}

SINK_URI="s3://${S3_BUCKET}/tici/cdc?protocol=canal-json&enable-tidb-extension=true&output-row-key=true&flush-interval=0.5s&access-key=${S3_ACCESS_KEY}&secret-access-key=${S3_SECRET_KEY}&endpoint=${S3_ENDPOINT}"

PD_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/component=pd -o jsonpath='{.items[0].metadata.name}')
if [[ -z "$PD_POD" ]]; then
  echo "[changefeed] Failed to find PD pod in namespace $NAMESPACE" >&2
  exit 1
fi
if ! kubectl exec -n "$NAMESPACE" "$PD_POD" -- /pd-ctl -u http://127.0.0.1:2379 keyspace list | grep -q "\"name\": \"${KEYSPACE_NAME}\""; then
  kubectl exec -n "$NAMESPACE" "$PD_POD" -- /pd-ctl -u http://127.0.0.1:2379 keyspace create "$KEYSPACE_NAME"
fi

kubectl rollout status -n "$NAMESPACE" statefulset/ticdc --timeout=15m
kubectl exec -n "$NAMESPACE" ticdc-0 -- /cdc cli changefeed create "--sink-uri=${SINK_URI}" --pd=http://pd-pd:2379 --changefeed-id "$CHANGEFEED_ID" --keyspace "$KEYSPACE_NAME" --no-confirm
kubectl exec -n "$NAMESPACE" ticdc-0 -- /cdc cli changefeed list --pd=http://pd-pd:2379 --keyspace "$KEYSPACE_NAME"

echo "[changefeed] Created changefeed: $CHANGEFEED_ID"
