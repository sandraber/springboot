#!/usr/bin/env bash
set -euo pipefail

IMAGE_REF="$1"

echo "$COSIGN_PUBLIC_KEY" > cosign.pub
cosign verify --key cosign.pub "$IMAGE_REF"
rm -f cosign.pub
