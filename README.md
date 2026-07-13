# sbx-pi-template

A minimal Docker image for running the [`pi`](https://github.com/badlogic/pi-mon) coding agent inside a [Docker Sandbox](https://docs.docker.com/ai/sandboxes/) (`sbx`).

Built on Docker's own `docker/sandbox-templates:shell-docker` base.

## What's included

- Docker's official `shell-docker` sandbox base
- Node.js 24 (Active LTS, supported through April 2028)
- [`pi`](https://www.npmjs.com/package/@mariozechner/pi-coding-agent) installed globally via npm

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

A [GitHub Actions workflow](.github/workflows/rebuild-template.yml) rebuilds and rescans this image weekly (Mondays, 06:00 UTC), and can be triggered manually via the **Actions** tab. Images are pushed to `ghcr.io/yourname/sbx-pi-template`, tagged by build date, plus a rolling `latest`.

## Using this template

This image is meant to be referenced from a kit, not run standalone. See [`sbx-pi-kit`](https://github.com/qunm00/sbx-pi-kit) for the full `spec.yaml` that wires this template up with network policy, credentials, and provider config.

For production use, pin to a digest rather than a date tag:
```bash
docker inspect ghcr.io/yourname/sbx-pi-template:2026-07-11-node24 --format='{{index .RepoDigests 0}}'
```

## Versioning

- `latest` — always the most recent successful weekly build
- `YYYY-MM-DD` — date-tagged snapshots, immutable
- Digest pins recommended for any long-term kit reference

## Security notes

- Every build is scanned for critical/high CVEs before push; the pipeline fails closed (a bad scan blocks the push, leaving the previous tag as the live `latest`).
