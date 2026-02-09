#!/bin/bash
set -e

# Setup git credentials for self-improvement
if [ -n "$GITHUB_TOKEN" ]; then
    echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > /data/.git-credentials
    git config --global credential.helper 'store --file /data/.git-credentials'
    echo "✅ Git credentials configured"
fi

# Start OpenClaw Gateway with auto bind
echo "🚀 Starting Edward (0xAudit)..."
PORT=${PORT:-8080}

# Try to patch the config to remove bind restriction
cat > /data/.openclaw/openclaw.json << 'EOF'
{
  "commands": { "native": "auto", "nativeSkills": "auto" },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "allowFrom": ["6937496786"],
      "groupPolicy": "disabled",
      "streamMode": "off"
    }
  },
  "gateway": { "port": 8080, "mode": "local" },
  "agents": { "defaults": { "maxConcurrent": 4, "subagents": { "maxConcurrent": 4 } } }
}
EOF

# Inject the actual bot token
sed -i "s|\${TELEGRAM_BOT_TOKEN}|8544736597:AAFPhQad2w06ndMbCIzru_mRTu5n0Volhns|g" /data/.openclaw/openclaw.json

exec openclaw gateway run --port $PORT --verbose 2>&1
