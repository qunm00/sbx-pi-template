# Multi-arch: the index is published for linux/amd64 and linux/arm64 so the
# image runs on sandbox hosts of either arch (sandboxes have no CPU emulation).
# $TARGETPLATFORM keeps each leg on its native base manifest.
ARG TARGETPLATFORM
# revdiff release to install (pi extension needs the binary on PATH)
ARG REVDIFF_VERSION=v1.13.0
FROM docker/sandbox-templates:shell-docker

USER root

# Install Node 24 (Active LTS, supported through April 2028)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install pi as the non-root user the shell-docker base runs as
USER agent
RUN mkdir -p "$HOME/.npm-global" \
    && npm config set prefix "$HOME/.npm-global" \
    && npm install -g --ignore-scripts @earendil-works/pi-coding-agent
ENV PATH="/home/agent/.npm-global/bin:${PATH}"

# Install pi extensions and skills (git-based)
RUN mkdir -p "$HOME/.pi/agent" \
    && pi install git:github.com/qunm00/pi-continual-learning \
    && pi install npm:@upstash/context7-pi \
    && pi install git:github.com/qunm00/pi-skills \
    && pi install npm:pi-ask-user-questions \
    && pi install git:github.com/obra/superpowers \
    && pi install git:github.com/AminBlg/SimpleEnglish \
    && pi install https://github.com/umputun/revdiff \
    && pi update \
    && pi update --extensions

# Install the revdiff binary. The pi extension only drives it, so a binary
# per target arch is needed; TARGETARCH comes from buildkit and matches the
# native base manifest. Pinned version + checksum, so the image is repeatable.
USER root
ARG TARGETARCH
ARG REVDIFF_VERSION
RUN set -eux; \
    arch="${TARGETARCH}"; \
    version="${REVDIFF_VERSION#v}"; \
    tarball="revdiff_${version}_linux_${arch}.tar.gz"; \
    base="https://github.com/umputun/revdiff/releases/download/v${version}"; \
    cd /tmp; \
    curl -fsSLO "${base}/${tarball}"; \
    curl -fsSLO "${base}/revdiff_${version}_checksums.txt"; \
    grep " ${tarball}\$" "revdiff_${version}_checksums.txt" | sha256sum -c -; \
    tar xzf "${tarball}" revdiff; \
    install -m 0755 revdiff /usr/local/bin/revdiff; \
    rm -rf "/tmp/${tarball}" "/tmp/revdiff_${version}_checksums.txt" "/tmp/revdiff"; \
    revdiff --version

USER agent
WORKDIR /workspace
