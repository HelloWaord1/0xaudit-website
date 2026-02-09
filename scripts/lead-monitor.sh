#!/bin/bash
LEADS_FILE="/data/.openclaw/workspace/business/new-leads.json"
API_URL="https://0-x-audit.com/api/leads"
API_SECRET="0xaudit-secret-2026"

while true; do
  curl -s "$API_URL" -H "X-Auth: $API_SECRET" 2>/dev/null | python3 -c "
import sys,json
try:
    data = json.load(sys.stdin)
    new = [l for l in data if l.get('status')=='new' and l.get('email')!='test@example.com']
    if new:
        with open('$LEADS_FILE', 'w') as f:
            json.dump(new, f, indent=2)
        print(f'[NEW] {len(new)} lead(s)')
except: pass
" 2>/dev/null
  sleep 300
done
