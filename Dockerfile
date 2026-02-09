FROM node:22-bookworm

# Install basic tools
RUN apt-get update && apt-get install -y \
    nmap \
    git \
    curl \
    jq \
    socat \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw
RUN npm install -g openclaw

# Setup workspace
WORKDIR /data
RUN mkdir -p /data/.openclaw/workspace

# Copy workspace files
COPY workspace/ /data/.openclaw/workspace/
COPY openclaw.json /data/.openclaw/openclaw.json

# Environment
ENV OPENCLAW_WORKSPACE=/data/.openclaw/workspace
ENV HOME=/data

# Git config for self-improvement
RUN git config --global user.name "Edward (0xAudit)" && \
    git config --global user.email "edward@0xaudit.ai" && \
    git config --global credential.helper store

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
