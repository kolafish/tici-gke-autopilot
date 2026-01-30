#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TF_DIR="$ROOT_DIR/terraform"

if [[ ! -f "$ROOT_DIR/config.env" ]]; then
  echo "[destroy] Missing config.env. Copy config.env.example and fill it in." >&2
  exit 1
fi
# shellcheck disable=SC1091
source "$ROOT_DIR/config.env"

: "${PROJECT_ID:?Missing PROJECT_ID in config.env}"
: "${REGION:?Missing REGION in config.env}"
: "${CLUSTER_NAME:?Missing CLUSTER_NAME in config.env}"

terraform -chdir="$TF_DIR" destroy -auto-approve
rm -f "$ROOT_DIR/.secrets.env"

# Optional: remove kubeconfig entry
if command -v kubectl >/dev/null 2>&1; then
  kubectl config delete-cluster "gke_${PROJECT_ID}_${REGION}_${CLUSTER_NAME}" >/dev/null 2>&1 || true
  kubectl config delete-context "gke_${PROJECT_ID}_${REGION}_${CLUSTER_NAME}" >/dev/null 2>&1 || true
  kubectl config unset "users.gke_${PROJECT_ID}_${REGION}_${CLUSTER_NAME}" >/dev/null 2>&1 || true
fi

echo "[destroy] Terraform resources destroyed"
