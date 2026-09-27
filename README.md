# sbx-pi-template

A minimal Docker image for running the [`pi`](https://github.com/badlogic/pi-mon) coding agent inside a [Docker Sandbox](https://docs.docker.com/ai/sandboxes/) (`sbx`).

Built on Docker's own `docker/sandbox-templates:shell-docker` base.

## What's included

- Docker's official `shell-docker` sandbox base
- Node.js 24 (Active LTS, supported through April 2028)
- [`pi`](https://github.com/earendil-works/pi) installed globally via npm
- [context7](https://github.com/upstash/context7/tree/master/packages/pi) extension installed globally
- [`pi-continual-learning`](https://github.com/qunm00/pi-continual-learning) extension installed globally
- [`pi-subagents`](https://github.com/tintinweb/pi-subagents) extension installed globally
- [`pi-skills`](https://github.com/qunm00/pi-skills) extension installed globally
- [`pi-ask-user-questions`](https://github.com/qunm00/pi-ask-user-questions) extension installed globally

## Build locally

```bash
docker build -t sbx-pi-template:local .
docker run --rm sbx-pi-template:local pi --version
docker run --rm -it sbx-pi-template:local
```

## Rebuild, scan, and push

```bash
./rebuild.sh
```

This builds a date-tagged image, verifies `pi` runs, scans for critical/high CVEs with Docker Scout (blocking the push on failure), and pushes to the registry.

## Automated rebuilds

A [GitHub Actions workflow](.github/workflows/rebuild-template.yml) rebuilds and rescans this image when a push to `main` touches `Dockerfile`, `rebuild.sh`, `README.md`, or the workflow file itself, and can also be triggered manually via the **Actions** tab. There is no scheduled rebuild. Images are pushed to Docker Hub as `nmiquan/sbx-pi-template`, tagged by build date, plus a rolling `latest`.

## Using this template

This image is meant to be referenced from a kit, not run standalone. See [`sbx-pi-kit`](https://github.com/qunm00/sbx-pi-kit) for the full `spec.yaml` that wires this template up with network policy, credentials, and provider config.

For production use, pin to a digest rather than a date tag:
```bash
docker buildx imagetools inspect nmiquan/sbx-pi-template:2026-09-26 --format '{{.Manifest.Digest}}'
# sha256:a074ffa617ac04dee41320440e6c6ec909f4c2ce44daa8544a6049b838e172d0
```

This resolves the multi-arch image index digest straight from the registry, with no local pull.

## Versioning

- `latest` — always the most recent successful build
- `YYYY-MM-DD` — date-tagged snapshots, immutable
- Digest pins recommended for any long-term kit reference

## Security notes

- Every build is scanned for critical/high CVEs before push; the pipeline fails closed (a bad scan blocks the push, leaving the previous tag as the live `latest`).
