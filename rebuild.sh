#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-qunm00/sbx-pi-template}"
TAG="${TAG:-$(date +%Y-%m-%d)}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"
LATEST_IMAGE="${IMAGE_NAME}:latest"

echo "==> Building ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" -t "${LATEST_IMAGE}" .

echo "==> Verifying pi runs"
docker run --rm "${FULL_IMAGE}" pi --version

echo "==> Scanning for critical/high CVEs"
docker scout cves "${FULL_IMAGE}" --only-severity critical,high --exit-code

echo "==> Pushing ${FULL_IMAGE}"
docker push "${FULL_IMAGE}"
docker push "${LATEST_IMAGE}"

echo "==> Done. Update your kit's spec.yaml to pin:"
echo "    image: ${FULL_IMAGE}"