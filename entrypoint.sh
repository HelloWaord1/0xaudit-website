#!/bin/bash
set -e

# Setup git credentials
if [ -n "$GITHUB_TOKEN" ]; then
    echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > /data/.git-credentials
    git config --global credential.helper 'store --file /data/.git-credentials'
    echo "✅ Git credentials configured"
fi

PORT=${PORT:-8080}
INTERNAL_PORT=8081

echo "🚀 Starting Edward (0xAudit)..."

# Start OpenClaw on internal port (binds to 127.0.0.1)
openclaw gateway run --port $INTERNAL_PORT --verbose &
GATEWAY_PID=$!

# Wait for gateway to start
sleep 3

# Proxy external 0.0.0.0:PORT → 127.0.0.1:INTERNAL_PORT
echo "🔗 Starting socat proxy on 0.0.0.0:$PORT → 127.0.0.1:$INTERNAL_PORT"
socat TCP-LISTEN:$PORT,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:$INTERNAL_PORT &
SOCAT_PID=$!

# Wait for either to exit
wait -n $GATEWAY_PID $SOCAT_PID
