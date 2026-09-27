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

`docker build` produces a single-arch image matching your host, which is all you
need locally. `./rebuild.sh` is what publishes the multi-arch tags.

## Platforms

The published tags are multi-arch index manifests covering `linux/amd64` and
`linux/arm64`. This matters: Docker sandboxes run the image on the host's
architecture with no CPU emulation, so a single-arch image fails on the other
arch with `image platform mismatch`. Check what a tag actually contains:

```bash
docker buildx imagetools inspect nmiquan/sbx-pi-template:latest
```

## Rebuild, scan, and push

```bash
./rebuild.sh
```

This builds a date-tagged image for every platform in `PLATFORMS`
(default `linux/amd64,linux/arm64`), verifies `pi` runs, scans for
critical/high CVEs with Docker Scout (blocking the push on failure), pushes,
and then re-inspects the pushed tag to confirm no platform went missing. Pushes
to Docker Hub as `nmiquan/sbx-pi-template`, tagged by build date, plus a rolling
`latest`.

On a single-arch host you need binfmt handlers for the other platform:

```bash
docker run --privileged --rm tonistiigi/binfmt --install arm64
```

Set `PLATFORMS=linux/arm64` to publish only your arch and skip that.

## Automated rebuilds

A [GitHub Actions workflow](.github/workflows/rebuild-template.yml) rebuilds and rescans this image when a push to `main` touches `Dockerfile`, `rebuild.sh`, `README.md`, or the workflow file itself, and can also be triggered manually via the **Actions** tab. The runner is `ubuntu-latest` (amd64) and QEMU + buildx are set up there so it can emit the arm64 leg. There is no scheduled rebuild. Images are pushed to Docker Hub as `nmiquan/sbx-pi-template`, tagged by build date, plus a rolling `latest`.

## Using this template

This image is meant to be referenced from a kit, not run standalone. See [`sbx-pi-kit`](https://github.com/qunm00/sbx-pi-kit) for the full `spec.yaml` that wires this template up with network policy, credentials, and provider config.

For production use, pin to a digest rather than a date tag:
```bash
docker buildx imagetools inspect nmiquan/sbx-pi-template:latest --format '{{.Manifest.Digest}}'
```

This resolves the multi-arch image index digest straight from the registry, with no local pull.

## Versioning

- `latest` — always the most recent successful build
- `YYYY-MM-DD` — date-tagged snapshots, immutable
- Digest pins recommended for any long-term kit reference

## Security notes

- Every build is scanned for critical/high CVEs before push; the pipeline fails closed (a bad scan blocks the push, leaving the previous tag as the live `latest`).
