#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-nmiquan/sbx-pi-template}"
TAG="${TAG:-$(date +%Y-%m-%d)}"
# Both are published: Docker sandboxes run on whatever arch the host is
# (often linux/arm64 on Apple Silicon) and there is no CPU emulation, so a
# single-arch image is unusable on the other arch.
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"
LATEST_IMAGE="${IMAGE_NAME}:latest"
BUILDER="${BUILDER:-sbx-multiarch}"

if ! docker info > /dev/null 2>&1; then
  echo "==> Authenticating with Docker Hub"
  if [ -z "${DOCKERHUB_USERNAME:-}" ] || [ -z "${DOCKERHUB_TOKEN:-}" ]; then
    echo "Error: DOCKERHUB_USERNAME and DOCKERHUB_TOKEN env vars not set"
    echo "Set them or run: docker login"
    exit 1
  fi
  echo "${DOCKERHUB_TOKEN}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin
fi

# Multi-platform builds need a container-driver builder; the plain "default"
# builder cannot build for foreign platforms.
builder_driver="$(docker buildx inspect 2>/dev/null | sed -n 's/^Driver:[[:space:]]*//p' | head -1)"
if [ "${builder_driver}" = "docker-container" ]; then
  echo "==> Using current buildx builder (docker-container)"
else
  if ! docker buildx inspect "${BUILDER}" > /dev/null 2>&1; then
    echo "==> Creating buildx builder ${BUILDER}"
    docker buildx create --name "${BUILDER}" --driver docker-container --use
  else
    docker buildx use "${BUILDER}"
  fi
fi
docker buildx inspect --bootstrap > /dev/null

echo "==> Building ${FULL_IMAGE} for ${PLATFORMS} (local arch, for verify + scan)"
# Single-platform --load build: the same Dockerfile steps, but emulated legs
# aren't needed here and the result can be run and scanned locally.
docker buildx build --load -t "${FULL_IMAGE}" .

echo "==> Verifying pi runs"
docker run --rm "${FULL_IMAGE}" pi --version

echo "==> Verifying revdiff runs"
docker run --rm "${FULL_IMAGE}" revdiff --version

echo "==> Scanning for critical/high CVEs"
docker scout cves "${FULL_IMAGE}" --only-severity critical,high --ignore-base

echo "==> Pushing ${FULL_IMAGE} for ${PLATFORMS}"
docker buildx build --platform "${PLATFORMS}" \
  -t "${FULL_IMAGE}" -t "${LATEST_IMAGE}" --push .

echo "==> Verifying every platform was published"
# A single-arch tag has no .Manifest.Manifests at all, so the inspect fails
# here and the platform comes back empty -- exactly what we want to catch.
published="$(docker buildx imagetools inspect \
  --format '{{range .Manifest.Manifests}}{{println .Platform.OS "/" .Platform.Architecture}}{{end}}' \
  "${LATEST_IMAGE}" 2>/dev/null | tr -d ' ' | grep '^linux/' || true)"
missing=0
for platform in ${PLATFORMS//,/ }; do
  if printf '%s\n' "${published}" | grep -qx "${platform}"; then
    echo "    ok: ${platform}"
  else
    echo "    MISSING: ${platform}"
    missing=1
  fi
done
if [ "${missing}" -ne 0 ]; then
  echo "Error: ${LATEST_IMAGE} is missing a platform (see above)"
  echo "       A single-arch tag breaks sandboxes on the other arch."
  exit 1
fi

echo "==> Done. Update your kit's spec.yaml to pin:"
echo "    image: ${FULL_IMAGE}"
