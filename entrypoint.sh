#!/bin/bash
set -ex

echo "=== Environment ==="
env | sort

echo "=== Git credentials ==="
if [ -n "$GITHUB_TOKEN" ]; then
    echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > /data/.git-credentials
    git config --global credential.helper 'store --file /data/.git-credentials'
    echo "✅ Git credentials configured"
fi

echo "=== Workspace ==="
ls -la /data/.openclaw/
ls -la /data/.openclaw/workspace/ || echo "No workspace"

echo "=== Config ==="
cat /data/.openclaw/openclaw.json

echo "=== OpenClaw version ==="
openclaw --version

echo "=== Starting OpenClaw Gateway ==="
PORT=${PORT:-8080}
exec openclaw gateway run --port $PORT --allow-unconfigured --verbose 2>&1
