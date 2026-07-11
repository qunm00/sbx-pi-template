#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-nmiquan/sbx-pi-template}"
TAG="${TAG:-$(date +%Y-%m-%d)}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"
LATEST_IMAGE="${IMAGE_NAME}:latest"

# Check if logged into Docker Hub
if ! docker info > /dev/null 2>&1; then
  echo "==> Authenticating with Docker Hub"
  if [ -z "${DOCKERHUB_USERNAME:-}" ] || [ -z "${DOCKERHUB_TOKEN:-}" ]; then
    echo "Error: DOCKERHUB_USERNAME and DOCKERHUB_TOKEN env vars not set"
    echo "Set them or run: docker login"
    exit 1
  fi
  echo "${DOCKERHUB_TOKEN}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin
fi

echo "==> Building ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" -t "${LATEST_IMAGE}" .

echo "==> Verifying pi runs"
docker run --rm "${FULL_IMAGE}" pi --version

echo "==> Scanning for critical/high CVEs"
docker scout cves "${FULL_IMAGE}" --only-severity critical,high --ignore-base

echo "==> Pushing ${FULL_IMAGE}"
docker push "${FULL_IMAGE}"
docker push "${LATEST_IMAGE}"

echo "==> Done. Update your kit's spec.yaml to pin:"
echo "    image: ${FULL_IMAGE}"