#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEMPLATE_DIR="$ROOT_DIR/manifests/templates"
OUT_DIR="$ROOT_DIR/manifests/rendered"

mkdir -p "$OUT_DIR"

required_vars=(
  NAMESPACE
  STORAGE_CLASS
  S3_BUCKET
  S3_ENDPOINT
  S3_REGION
  S3_ACCESS_KEY
  S3_SECRET_KEY
  S3_USE_PATH_STYLE
  MINIO_REPLICAS
  MINIO_IMAGE
  MYSQL_CLIENT_IMAGE
  BUSYBOX_IMAGE
  TIDB_HELPER_IMAGE
  TIDB_BASE_IMAGE
  TIDB_VERSION
  TIDB_REPLICAS
  TIDB_WORKER_REPLICAS
  TIKV_BASE_IMAGE
  TIKV_VERSION
  TIKV_REPLICAS
  TIKV_WORKER_REPLICAS
  TIKV_WORKER_IMAGE
  PD_BASE_IMAGE
  PD_VERSION
  PD_REPLICAS
  TIFLASH_IMAGE
  TIFLASH_CN_REPLICAS
  TICDC_IMAGE
  TICDC_REPLICAS
  TICI_IMAGE
  TICI_META_REPLICAS
  TICI_WORKER_REPLICAS
  TIDB_OPERATOR_IMAGE
  TIDB_DISCOVERY_IMAGE
)

missing=0
for v in "${required_vars[@]}"; do
  if [[ -z "${!v:-}" ]]; then
    echo "[render] Missing env var: $v" >&2
    missing=1
  fi
done
if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

vars='$NAMESPACE $STORAGE_CLASS $S3_BUCKET $S3_ENDPOINT $S3_REGION $S3_ACCESS_KEY $S3_SECRET_KEY $S3_USE_PATH_STYLE '
vars+='$MINIO_REPLICAS $MINIO_IMAGE $MYSQL_CLIENT_IMAGE $BUSYBOX_IMAGE $TIDB_HELPER_IMAGE '
vars+='$TIDB_BASE_IMAGE $TIDB_VERSION $TIDB_REPLICAS $TIDB_WORKER_REPLICAS '
vars+='$TIKV_BASE_IMAGE $TIKV_VERSION $TIKV_REPLICAS $TIKV_WORKER_REPLICAS $TIKV_WORKER_IMAGE '
vars+='$PD_BASE_IMAGE $PD_VERSION $PD_REPLICAS $TIFLASH_IMAGE $TIFLASH_CN_REPLICAS '
vars+='$TICDC_IMAGE $TICDC_REPLICAS $TICI_IMAGE $TICI_META_REPLICAS $TICI_WORKER_REPLICAS '
vars+='$TIDB_OPERATOR_IMAGE $TIDB_DISCOVERY_IMAGE'

for f in "$TEMPLATE_DIR"/*.yaml; do
  name=$(basename "$f")
  envsubst "$vars" < "$f" > "$OUT_DIR/$name"
done

# Safety: do not keep rendered manifests if they contain unresolved placeholders.
if command -v rg >/dev/null 2>&1; then
  if rg -n "\$\{[A-Z0-9_]+\}" "$OUT_DIR" >/dev/null; then
    echo "[render] Unresolved placeholders detected in rendered manifests." >&2
    rg -n "\$\{[A-Z0-9_]+\}" "$OUT_DIR" >&2 || true
    exit 1
  fi
fi

echo "[render] Rendered manifests to $OUT_DIR"
