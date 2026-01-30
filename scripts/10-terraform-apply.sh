#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TF_DIR="$ROOT_DIR/terraform"

if [[ ! -f "$ROOT_DIR/config.env" ]]; then
  echo "[terraform] Missing config.env. Copy config.env.example and fill it in." >&2
  exit 1
fi
# shellcheck disable=SC1091
source "$ROOT_DIR/config.env"

: "${PROJECT_ID:?Missing PROJECT_ID in config.env}"
: "${REGION:?Missing REGION in config.env}"
: "${CLUSTER_NAME:?Missing CLUSTER_NAME in config.env}"

export TF_VAR_project_id="$PROJECT_ID"
export TF_VAR_region="$REGION"
export TF_VAR_cluster_name="$CLUSTER_NAME"
export TF_VAR_bucket_location="${BUCKET_LOCATION:-$REGION}"
export TF_VAR_network="${NETWORK:-default}"
export TF_VAR_subnetwork="${SUBNETWORK:-default}"

terraform -chdir="$TF_DIR" init
terraform -chdir="$TF_DIR" apply -auto-approve

gcloud config set project "$PROJECT_ID"
gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION"

kubectl cluster-info
