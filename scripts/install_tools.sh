#!/usr/bin/env bash
set -euo pipefail

# Trivy
if ! command -v trivy >/dev/null; then
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin
fi

# Cosign
if ! command -v cosign >/dev/null; then
  COSIGN_VERSION=v2.2.4
  curl -sfL https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64 -o cosign
  chmod +x cosign
  sudo mv cosign /usr/local/bin/cosign
fi

# kubectl
if ! command -v kubectl >/dev/null; then
  KUBECTL_VERSION=$(curl -s https://dl.k8s.io/release/stable.txt)
  curl -sfL https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o kubectl
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/kubectl
fi

# helm
if ! command -v helm >/dev/null; then
  curl -sfL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
