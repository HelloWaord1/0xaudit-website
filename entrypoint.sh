#!/bin/bash
set -e

# Setup git credentials
if [ -n "$GITHUB_TOKEN" ]; then
    echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > /data/.git-credentials
    git config --global credential.helper 'store --file /data/.git-credentials'
    echo "✅ Git credentials configured"
fi

echo "🚀 Starting Edward (0xAudit)..."
PORT=${PORT:-8080}
exec openclaw gateway run --port $PORT --verbose
