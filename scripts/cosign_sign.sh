#!/usr/bin/env bash
set -euo pipefail

IMAGE_REF="$1"

echo "$COSIGN_PRIVATE_KEY" > cosign.key
cosign sign --key cosign.key "$IMAGE_REF"
rm -f cosign.key
