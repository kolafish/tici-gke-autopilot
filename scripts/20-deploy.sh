#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TF_DIR="$ROOT_DIR/terraform"
RENDER_SCRIPT="$ROOT_DIR/scripts/render.sh"
SECRETS_ENV="$ROOT_DIR/.secrets.env"

if [[ ! -f "$ROOT_DIR/config.env" ]]; then
  echo "[deploy] Missing config.env. Copy config.env.example and fill it in." >&2
  exit 1
fi
# shellcheck disable=SC1091
source "$ROOT_DIR/config.env"

: "${PROJECT_ID:?Missing PROJECT_ID in config.env}"
: "${REGION:?Missing REGION in config.env}"
: "${CLUSTER_NAME:?Missing CLUSTER_NAME in config.env}"

NAMESPACE=${NAMESPACE:-tidb-fts}
STORAGE_CLASS=${STORAGE_CLASS:-premium-rwo}
STORAGE_MODE=${STORAGE_MODE:-gcs}
KEYSPACE_NAME=${KEYSPACE_NAME:-default}
SYSTEM_KEYSPACE_NAME=${SYSTEM_KEYSPACE_NAME:-SYSTEM}

# Default replicas (align with terraform-tici locals_common.tf)
PD_REPLICAS=${PD_REPLICAS:-1}
TIDB_REPLICAS=${TIDB_REPLICAS:-1}
TIDB_WORKER_REPLICAS=${TIDB_WORKER_REPLICAS:-1}
TIKV_REPLICAS=${TIKV_REPLICAS:-1}
TIKV_WORKER_REPLICAS=${TIKV_WORKER_REPLICAS:-1}
TIFLASH_CN_REPLICAS=${TIFLASH_CN_REPLICAS:-1}
TICDC_REPLICAS=${TICDC_REPLICAS:-1}
TICI_META_REPLICAS=${TICI_META_REPLICAS:-1}
TICI_WORKER_REPLICAS=${TICI_WORKER_REPLICAS:-1}
MINIO_REPLICAS=${MINIO_REPLICAS:-1}

# Default images
TIDB_BASE_IMAGE=${TIDB_BASE_IMAGE:-gcr.io/pingcap-public/tidbcloud/tidb}
TIDB_VERSION=${TIDB_VERSION:-feature-fts-dc593c5-next-gen}
TIKV_BASE_IMAGE=${TIKV_BASE_IMAGE:-gcr.io/pingcap-public/tidbcloud/tikv}
TIKV_VERSION=${TIKV_VERSION:-v8.5.4-nextgen.202510.10}
PD_BASE_IMAGE=${PD_BASE_IMAGE:-gcr.io/pingcap-public/tidbcloud/pd}
PD_VERSION=${PD_VERSION:-v8.5.4-nextgen.202510.4}
TIKV_WORKER_IMAGE=${TIKV_WORKER_IMAGE:-gcr.io/pingcap-public/tidbcloud/tikv:v8.5.4-nextgen.202510.10}
TIFLASH_IMAGE=${TIFLASH_IMAGE:-gcr.io/pingcap-public/tidbcloud/tiflash:feature-fts-613d48e-next-gen}
TICDC_IMAGE=${TICDC_IMAGE:-gcr.io/pingcap-public/tidbcloud/ticdc:v8.5.4-nextgen.202510.3}
TICI_IMAGE=${TICI_IMAGE:-gcr.io/pingcap-public/tidbcloud/tici:master}
TIDB_OPERATOR_IMAGE=${TIDB_OPERATOR_IMAGE:-gcr.io/pingcap-public/tidbcloud/serverless/tidb-operator:ce1637cc2fc5434c41ee1a6094a93d45e10af502}
TIDB_DISCOVERY_IMAGE=${TIDB_DISCOVERY_IMAGE:-$TIDB_OPERATOR_IMAGE}
BUSYBOX_IMAGE=${BUSYBOX_IMAGE:-gcr.io/pingcap-public/dbaas/busybox:1.31.1}
TIDB_HELPER_IMAGE=${TIDB_HELPER_IMAGE:-$BUSYBOX_IMAGE}
MINIO_IMAGE=${MINIO_IMAGE:-quay.io/minio/minio:latest}
MYSQL_CLIENT_IMAGE=${MYSQL_CLIENT_IMAGE:-docker.io/mysql:lts}

S3_REGION=${S3_REGION:-$REGION}

if [[ "$STORAGE_MODE" == "gcs" ]]; then
  if [[ ! -d "$TF_DIR" ]]; then
    echo "[deploy] Terraform directory not found: $TF_DIR" >&2
    exit 1
  fi
  S3_BUCKET=$(terraform -chdir="$TF_DIR" output -raw bucket_name)
  S3_ACCESS_KEY=$(terraform -chdir="$TF_DIR" output -raw hmac_access_id)
  S3_SECRET_KEY=$(terraform -chdir="$TF_DIR" output -raw hmac_secret)
  S3_ENDPOINT=${S3_ENDPOINT:-https://storage.googleapis.com}
  S3_USE_PATH_STYLE=${S3_USE_PATH_STYLE:-false}
else
  S3_BUCKET=${S3_BUCKET:-tici}
  S3_ACCESS_KEY=${S3_ACCESS_KEY:-$(openssl rand -hex 8)}
  S3_SECRET_KEY=${S3_SECRET_KEY:-$(openssl rand -hex 16)}
  S3_ENDPOINT=${S3_ENDPOINT:-http://minio.${NAMESPACE}.svc.cluster.local:9000}
  S3_USE_PATH_STYLE=${S3_USE_PATH_STYLE:-true}
fi

cat > "$SECRETS_ENV" <<EOF
STORAGE_MODE=$STORAGE_MODE
S3_BUCKET=$S3_BUCKET
S3_ACCESS_KEY=$S3_ACCESS_KEY
S3_SECRET_KEY=$S3_SECRET_KEY
S3_ENDPOINT=$S3_ENDPOINT
S3_REGION=$S3_REGION
S3_USE_PATH_STYLE=$S3_USE_PATH_STYLE
EOF

export NAMESPACE STORAGE_CLASS STORAGE_MODE
export KEYSPACE_NAME SYSTEM_KEYSPACE_NAME
export PD_REPLICAS TIDB_REPLICAS TIDB_WORKER_REPLICAS TIKV_REPLICAS TIKV_WORKER_REPLICAS
export TIFLASH_CN_REPLICAS TICDC_REPLICAS TICI_META_REPLICAS TICI_WORKER_REPLICAS MINIO_REPLICAS
export TIDB_BASE_IMAGE TIDB_VERSION TIKV_BASE_IMAGE TIKV_VERSION PD_BASE_IMAGE PD_VERSION
export TIKV_WORKER_IMAGE TIFLASH_IMAGE TICDC_IMAGE TICI_IMAGE TIDB_OPERATOR_IMAGE TIDB_DISCOVERY_IMAGE
export BUSYBOX_IMAGE TIDB_HELPER_IMAGE MINIO_IMAGE MYSQL_CLIENT_IMAGE
export S3_BUCKET S3_ACCESS_KEY S3_SECRET_KEY S3_ENDPOINT S3_REGION S3_USE_PATH_STYLE

"$RENDER_SCRIPT"

# Core setup
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f "$ROOT_DIR/manifests/rendered/crd.yaml" --server-side
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/service-account.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/role.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/rolebinding.yaml"
kubectl apply -f "$ROOT_DIR/manifests/rendered/clusterrole.yaml"
kubectl apply -f "$ROOT_DIR/manifests/rendered/clusterrolebinding.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/operator.yaml"

kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/bootstrap.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/tici-meta-config.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/tici-worker-config.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/tiflash-cn-config.yaml"

if [[ "$STORAGE_MODE" == "minio" ]]; then
  kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/minio.yaml"
  kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/minio-svc.yaml"
  kubectl rollout status -n "$NAMESPACE" statefulset/minio --timeout=15m
  kubectl exec -n "$NAMESPACE" minio-0 -- mc alias set local http://localhost:9000 "$S3_ACCESS_KEY" "$S3_SECRET_KEY"
  kubectl exec -n "$NAMESPACE" minio-0 -- mc mb --ignore-existing "local/$S3_BUCKET"
fi

# Services for TiCI/TiCDC/TiKV-Worker/TiFlash
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/tici-meta-svc.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/tici-worker-svc.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/ticdc-svc.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/tikv-worker-svc.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/tiflash-cn-svc.yaml"

# Core components
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/pd.yaml"
kubectl rollout status -n "$NAMESPACE" statefulset/pd-pd --timeout=15m

PD_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/component=pd -o jsonpath='{.items[0].metadata.name}')
if [[ -z "$PD_POD" ]]; then
  echo "[deploy] Failed to find PD pod in namespace $NAMESPACE" >&2
  exit 1
fi
if ! kubectl exec -n "$NAMESPACE" "$PD_POD" -- /pd-ctl -u http://127.0.0.1:2379 keyspace list | grep -q "\"name\": \"${KEYSPACE_NAME}\""; then
  kubectl exec -n "$NAMESPACE" "$PD_POD" -- /pd-ctl -u http://127.0.0.1:2379 keyspace create "$KEYSPACE_NAME"
fi
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/tikv.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/tikv-worker.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/tidb-worker.yaml"

kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/tidb.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/ticdc.yaml"

kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/tici-meta.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/tici-worker.yaml"
kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/tiflash-cn.yaml"

kubectl apply -n "$NAMESPACE" -f "$ROOT_DIR/manifests/rendered/mysql-client.yaml"

echo "[deploy] Applied manifests. Check pods with: kubectl get pods -n $NAMESPACE"
