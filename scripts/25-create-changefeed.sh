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
: "${S3_BUCKET:?Missing S3_BUCKET}"
: "${S3_ACCESS_KEY:?Missing S3_ACCESS_KEY}"
: "${S3_SECRET_KEY:?Missing S3_SECRET_KEY}"
: "${S3_ENDPOINT:?Missing S3_ENDPOINT}"

CHANGEFEED_ID=${CHANGEFEED_ID:-tici}

SINK_URI="s3://${S3_BUCKET}/tici/cdc?protocol=canal-json&enable-tidb-extension=true&output-row-key=true&flush-interval=0.5s&access-key=${S3_ACCESS_KEY}&secret-access-key=${S3_SECRET_KEY}&endpoint=${S3_ENDPOINT}"

kubectl rollout status -n "$NAMESPACE" statefulset/ticdc --timeout=15m
kubectl exec -n "$NAMESPACE" ticdc-0 -- /cdc cli changefeed create "--sink-uri=${SINK_URI}" --pd=http://pd-pd:2379 --changefeed-id "$CHANGEFEED_ID"
kubectl exec -n "$NAMESPACE" ticdc-0 -- /cdc cli changefeed list --pd=http://pd-pd:2379

echo "[changefeed] Created changefeed: $CHANGEFEED_ID"
