FROM node:22-bookworm

# Install security tools (lightweight)
RUN apt-get update && apt-get install -y \
    nmap \
    git \
    curl \
    jq \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install nuclei (web vuln scanner)
RUN curl -sSL https://github.com/projectdiscovery/nuclei/releases/download/v3.1.10/nuclei_3.1.10_linux_amd64.zip -o /tmp/nuclei.zip && \
    unzip /tmp/nuclei.zip -d /usr/local/bin && \
    rm /tmp/nuclei.zip && \
    nuclei -update-templates

# Install httpx (web prober)
RUN curl -sSL https://github.com/projectdiscovery/httpx/releases/download/v1.6.0/httpx_1.6.0_linux_amd64.zip -o /tmp/httpx.zip && \
    unzip /tmp/httpx.zip -d /usr/local/bin && \
    rm /tmp/httpx.zip

# Install subfinder (subdomain discovery)
RUN curl -sSL https://github.com/projectdiscovery/subfinder/releases/download/v2.6.3/subfinder_2.6.3_linux_amd64.zip -o /tmp/subfinder.zip && \
    unzip /tmp/subfinder.zip -d /usr/local/bin && \
    rm /tmp/subfinder.zip

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

# Init workspace as git repo (will clone on first run)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Run OpenClaw
CMD ["/entrypoint.sh"]
