#!/bin/bash
set -x

echo "=== Git credentials ==="
if [ -n "$GITHUB_TOKEN" ]; then
    echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > /data/.git-credentials
    git config --global credential.helper 'store --file /data/.git-credentials'
    echo "✅ Git credentials configured"
fi

echo "=== Testing OpenClaw ==="
openclaw status --all 2>&1 || echo "Status failed (expected)"

echo "=== Starting OpenClaw Gateway ==="
PORT=${PORT:-8080}

# Run without exec to capture errors
openclaw gateway run --port $PORT --allow-unconfigured --verbose 2>&1

echo "=== Gateway exited with code $? ==="
