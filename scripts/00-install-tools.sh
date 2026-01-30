#!/usr/bin/env bash
set -euo pipefail

OS=$(uname -s | tr '[:upper:]' '[:lower:]')

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  echo "[install] Homebrew not found, installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_gcloud_mac() {
  ensure_brew
  brew install --cask google-cloud-sdk
}

install_kubectl_mac() {
  ensure_brew
  brew install kubectl
}

install_terraform_mac() {
  ensure_brew
  brew install terraform
}

install_gcloud_linux() {
  echo "[install] Installing gcloud SDK (user install)..."
  curl -sSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir="$HOME/.local"
  # shellcheck disable=SC1091
  source "$HOME/.local/google-cloud-sdk/path.bash.inc"
}

install_kubectl_linux() {
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y kubectl
    return
  fi
  echo "[install] Please install kubectl manually for your distro."
  exit 1
}

install_terraform_linux() {
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y terraform || true
  else
    echo "[install] Please install terraform manually for your distro."
    exit 1
  fi
}

if ! command -v gcloud >/dev/null 2>&1; then
  if [[ "$OS" == "darwin"* ]]; then
    install_gcloud_mac
  else
    install_gcloud_linux
  fi
else
  echo "[install] gcloud already installed"
fi

if ! command -v kubectl >/dev/null 2>&1; then
  if [[ "$OS" == "darwin"* ]]; then
    install_kubectl_mac
  else
    install_kubectl_linux
  fi
else
  echo "[install] kubectl already installed"
fi

if ! command -v terraform >/dev/null 2>&1; then
  if [[ "$OS" == "darwin"* ]]; then
    install_terraform_mac
  else
    install_terraform_linux
  fi
else
  echo "[install] terraform already installed"
fi

# Disable prompts for gcloud components installs
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

# Authenticate if needed
if ! gcloud auth list --format="value(account)" | grep -q .; then
  echo "[install] gcloud not authenticated, please run: gcloud auth login"
fi
