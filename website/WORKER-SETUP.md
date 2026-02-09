# Contact Form — Cloudflare Worker Setup

## Architecture
```
User submits form → POST /api/contact → Cloudflare Worker:
  1. Saves lead to KV store
  2. Sends auto-reply email via MailChannels → client inbox
  3. Sends Telegram notification → Yava (6937496786)
```

## Endpoints

### POST /api/contact
- **Body:** `{ name, email, company?, service?, message }`
- **Returns:** `{ success: true }`
- **CORS:** `https://0-x-audit.com`

### GET /api/leads
- **Auth:** `X-Api-Key` header or `?key=` param
- **API Key:** `a20bd7d61889db1802be1a3fbd464b93`
- **Returns:** `{ success: true, count, leads: [...] }`

### GET /api/leads/:id
- Same auth as above

## Usage — Fetch Leads
```bash
curl -H "X-Api-Key: a20bd7d61889db1802be1a3fbd464b93" https://0-x-audit.com/api/leads
```

## Infrastructure

| Component | ID / Value |
|-----------|-----------|
| Worker | `contact-form` |
| KV Namespace | `e1e0d860e4114be69a592b656fe3bf5c` (contact-leads) |
| Route | `0-x-audit.com/api/*` → contact-form |
| API Key (leads) | `a20bd7d61889db1802be1a3fbd464b93` |

## DNS Records Added
- `TXT 0-x-audit.com` → `v=spf1 a mx include:relay.mailchannels.net ~all`
- `TXT _mailchannels.0-x-audit.com` → `v=mc1 cfid=0fc99af0782b972727147e386ea2c17e.workers.dev`

## Environment Variables
| Name | Type | Description |
|------|------|-------------|
| `LEADS` | KV binding | Lead storage |
| `TELEGRAM_BOT_TOKEN` | Secret | Bot token for notifications |
| `TELEGRAM_CHAT_ID` | Plain | `6937496786` |
| `API_KEY` | Plain | For /api/leads auth |

## Auto-Reply Email
- **From:** `noreply@0-x-audit.com`
- **Reply-To:** `audit0x_ai_new@proton.me`
- **Provider:** MailChannels (free via Cloudflare Workers)

## Date: 2026-02-09
