#!/bin/bash
set -e

# Setup git credentials if GITHUB_TOKEN is provided
if [ -n "$GITHUB_TOKEN" ]; then
    echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > /data/.git-credentials
    git config --global credential.helper 'store --file /data/.git-credentials'
    echo "✅ Git credentials configured"
fi

# Clone/update workspace repo
REPO_URL="https://github.com/HelloWaord1/0xaudit-agent.git"
WORKSPACE_DIR="/data/.openclaw/workspace"

if [ -d "$WORKSPACE_DIR/.git" ]; then
    echo "📦 Pulling latest workspace..."
    cd "$WORKSPACE_DIR"
    git pull origin main || true
else
    echo "📦 Cloning workspace..."
    rm -rf "$WORKSPACE_DIR"
    git clone "$REPO_URL" /tmp/repo
    mv /tmp/repo/workspace "$WORKSPACE_DIR"
    cd "$WORKSPACE_DIR"
    git init
    git remote add origin "$REPO_URL"
fi

# Start OpenClaw Gateway (foreground mode for Docker)
echo "🚀 Starting OpenClaw..."
# Use Railway's PORT or default to 8080
PORT=${PORT:-8080}
exec openclaw gateway run --bind auto --port $PORT --verbose
