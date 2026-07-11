#!/usr/bin/env bash
set -euo pipefail

# Defaults to GHCR; override with IMAGE_NAME env var for local testing
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/qunm/sbx-pi-template}"
TAG="${TAG:-$(date +%Y-%m-%d)}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"
LATEST_IMAGE="${IMAGE_NAME}:latest"

# Check if we're in GitHub Actions (GITHUB_TOKEN is set)
if [ -z "${GITHUB_TOKEN:-}" ] && [[ "${IMAGE_NAME}" == ghcr.io* ]]; then
  echo "==> Logging in to ghcr.io"
  echo "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_ACTOR:-}" --password-stdin
fi

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