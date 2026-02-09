FROM node:22-bookworm

# Install security tools
RUN apt-get update && apt-get install -y \
    nmap \
    python3-pip \
    python3-venv \
    git \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Python security tools in venv
RUN python3 -m venv /opt/security-tools && \
    /opt/security-tools/bin/pip install --upgrade pip && \
    /opt/security-tools/bin/pip install slither-analyzer mythril

# Add venv to PATH
ENV PATH="/opt/security-tools/bin:$PATH"

# Install nuclei
RUN curl -sSL https://github.com/projectdiscovery/nuclei/releases/download/v3.1.0/nuclei_3.1.0_linux_amd64.zip -o /tmp/nuclei.zip && \
    unzip /tmp/nuclei.zip -d /usr/local/bin && \
    rm /tmp/nuclei.zip

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

# Run OpenClaw
CMD ["openclaw", "gateway", "start", "--foreground"]
