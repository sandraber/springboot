#!/usr/bin/env bash
set -euo pipefail

IMAGE="$1"
trivy image --severity CRITICAL --exit-code 1 --no-progress "$IMAGE"