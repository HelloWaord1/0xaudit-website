#!/bin/bash
set -e

# Setup git credentials for self-improvement
if [ -n "$GITHUB_TOKEN" ]; then
    echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > /data/.git-credentials
    git config --global credential.helper 'store --file /data/.git-credentials'
    echo "✅ Git credentials configured"
fi

# For Railway: need to bind to 0.0.0.0
# OpenClaw uses HOST env var for custom bind
export HOST="0.0.0.0"

# Start OpenClaw Gateway
echo "🚀 Starting Edward (0xAudit) on 0.0.0.0:${PORT:-8080}..."
PORT=${PORT:-8080}
exec openclaw gateway run --port $PORT --bind lan --verbose
