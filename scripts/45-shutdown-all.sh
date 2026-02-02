#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TF_DIR="$ROOT_DIR/terraform"

if [[ ! -f "$ROOT_DIR/config.env" ]]; then
  echo "[shutdown] Missing config.env. Copy config.env.example and fill it in." >&2
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
export TF_VAR_manage_apis="${MANAGE_APIS:-true}"

if [[ "${CONFIRM_DESTROY:-}" != "yes" ]]; then
  cat <<MSG
[shutdown] This will delete the GKE cluster, GCS bucket, service account, HMAC key(s), and local kubeconfig entries.
[shutdown] Set CONFIRM_DESTROY=yes to proceed, e.g.:
  CONFIRM_DESTROY=yes scripts/45-shutdown-all.sh
MSG
  exit 1
fi

bucket_name=""
sa_email=""
hmac_access_id=""

if command -v terraform >/dev/null 2>&1 && [[ -d "$TF_DIR" ]]; then
  bucket_name=$(terraform -chdir="$TF_DIR" output -raw bucket_name 2>/dev/null || true)
  sa_email=$(terraform -chdir="$TF_DIR" output -raw service_account_email 2>/dev/null || true)
  hmac_access_id=$(terraform -chdir="$TF_DIR" output -raw hmac_access_id 2>/dev/null || true)
fi

if [[ -f "$TF_DIR/terraform.tfstate" ]] && { [[ -z "$bucket_name" ]] || [[ -z "$sa_email" ]] || [[ -z "$hmac_access_id" ]]; }; then
  if command -v python >/dev/null 2>&1; then
    eval "$(TFSTATE_PATH="$TF_DIR/terraform.tfstate" python - <<'PY'
import json
import os
from pathlib import Path

path = Path(os.environ['TFSTATE_PATH'])
data = json.loads(path.read_text())
outs = data.get('outputs', {})

def out(name, env):
    val = outs.get(name, {}).get('value', '')
    print(f"{env}={val!r}")

out('bucket_name', 'TF_BUCKET_NAME')
out('service_account_email', 'TF_SERVICE_ACCOUNT_EMAIL')
out('hmac_access_id', 'TF_HMAC_ACCESS_ID')
PY
)"

    if [[ -z "$bucket_name" && -n "${TF_BUCKET_NAME:-}" ]]; then
      bucket_name="$TF_BUCKET_NAME"
    fi
    if [[ -z "$sa_email" && -n "${TF_SERVICE_ACCOUNT_EMAIL:-}" ]]; then
      sa_email="$TF_SERVICE_ACCOUNT_EMAIL"
    fi
    if [[ -z "$hmac_access_id" && -n "${TF_HMAC_ACCESS_ID:-}" ]]; then
      hmac_access_id="$TF_HMAC_ACCESS_ID"
    fi
  else
    echo "[shutdown] python not found; skipping tfstate parsing." >&2
  fi
fi

echo "[shutdown] Starting terraform destroy (if available)..."
if command -v terraform >/dev/null 2>&1 && [[ -d "$TF_DIR" ]]; then
  terraform -chdir="$TF_DIR" init >/dev/null 2>&1 || true
  if ! terraform -chdir="$TF_DIR" destroy -auto-approve; then
    echo "[shutdown] terraform destroy failed; continuing with gcloud cleanup." >&2
  fi
else
  echo "[shutdown] terraform not found; skipping terraform destroy." >&2
fi

if command -v gcloud >/dev/null 2>&1; then
  gcloud config set project "$PROJECT_ID" >/dev/null 2>&1 || true

  echo "[shutdown] Deleting GKE cluster (best-effort)..."
  gcloud container clusters delete "$CLUSTER_NAME" --region "$REGION" --quiet >/dev/null 2>&1 || true

  if [[ -n "$hmac_access_id" && -n "$sa_email" ]]; then
    echo "[shutdown] Deleting GCS HMAC key (best-effort)..."
    gcloud storage hmac delete "$hmac_access_id" --service-account="$sa_email" --quiet >/dev/null 2>&1 || true
  fi

  if [[ -n "$sa_email" ]]; then
    echo "[shutdown] Deleting service account (best-effort)..."
    gcloud iam service-accounts delete "$sa_email" --quiet >/dev/null 2>&1 || true
  fi

  if [[ -n "$bucket_name" ]]; then
    echo "[shutdown] Deleting GCS bucket (best-effort)..."
    if ! gcloud storage rm -r "gs://$bucket_name" >/dev/null 2>&1; then
      if command -v gsutil >/dev/null 2>&1; then
        gsutil -m rm -r "gs://$bucket_name" >/dev/null 2>&1 || true
      fi
    fi
  fi
else
  echo "[shutdown] gcloud not found; skipping explicit GCP cleanup." >&2
fi

rm -f "$ROOT_DIR/.secrets.env" || true

if command -v kubectl >/dev/null 2>&1; then
  kubectl config delete-cluster "gke_${PROJECT_ID}_${REGION}_${CLUSTER_NAME}" >/dev/null 2>&1 || true
  kubectl config delete-context "gke_${PROJECT_ID}_${REGION}_${CLUSTER_NAME}" >/dev/null 2>&1 || true
  kubectl config unset "users.gke_${PROJECT_ID}_${REGION}_${CLUSTER_NAME}" >/dev/null 2>&1 || true
fi

echo "[shutdown] Done. Please verify in GCP console that no billable resources remain."
