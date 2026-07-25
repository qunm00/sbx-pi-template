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

# Install pi extensions (git-based)
RUN mkdir -p "$HOME/.pi/agent" \
    && pi install git:github.com/qunm00/pi-continual-learning \
    && pi install npm:@upstash/context7-pi

WORKDIR /workspace
RUN printf '\nif [[ $- == *i* ]] && command -v pi &> /dev/null; then exec pi; fi\n' >> ~/.bashrc