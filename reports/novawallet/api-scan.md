# 🛡️ API & Endpoint Discovery Audit — NovaWallet

**Auditor:** Edward @ 0xAudit  
**Date:** 2026-02-09  
**Target:** app.novawallet.org, api.novawallet.org, novawallet.org  
**API Version:** Nova Wallet API v5.5.1  

---

## Executive Summary

NovaWallet is a crypto payment PWA (Progressive Web App) for PromptPay QR payments in Thailand using USDT/KAIA. The frontend at `app.novawallet.org` is an SPA served via Cloudflare. The backend API lives at `api.novawallet.org`. The marketing site at `novawallet.org` is hosted on Tilda CMS.

**Overall Risk: MEDIUM** — Several misconfigurations found, primarily around CORS policy, verbose error messages, and missing security headers. No critical data exposure discovered.

---

## Architecture Discovered

| Component | URL | Technology |
|-----------|-----|------------|
| Frontend (PWA/SPA) | app.novawallet.org | Vanilla JS, Web Components, Cloudflare |
| Backend API | api.novawallet.org | REST API v5.5.1, Cloudflare, JWT auth |
| Marketing site | novawallet.org | Tilda CMS, Cloudflare |
| Documentation | docs.novawallet.org | GitBook (Next.js) |
| OAuth Providers | LINE, Google | OAuth2 |
| Crypto networks | BSC, KAIA (Klaytn) | EVM chains |
| Third-party | buy.onramper.dev | Fiat on-ramp |
| Analytics | Contentsquare/Hotjar | Session tracking |

---

## Endpoint Map

### api.novawallet.org — Authenticated Endpoints (401)

| Endpoint | Method | Auth Required | Notes |
|----------|--------|---------------|-------|
| `/` | GET | No | Returns "Nova Wallet API v5.5.1" |
| `/admin` | GET | Yes (401: "Unauthorized") | Admin panel exists |
| `/wallet` | GET | Yes | "Token not provided" |
| `/wallet/balance` | GET | Yes | "Token not provided" |
| `/wallet/info` | GET | Yes | "Token not provided" |
| `/wallet/address` | GET | Yes | "Token not provided" |
| `/wallet/keys` | GET | Yes | ⚠️ Key export endpoint exists |
| `/wallet/seed` | GET | Yes | ⚠️ Seed phrase endpoint exists |
| `/wallet/export` | GET | Yes | ⚠️ Export endpoint exists |
| `/wallet/transactions` | GET | Yes | "Token not provided" |
| `/wallet/history` | GET | Yes | "Token not provided" |
| `/wallet/send` | GET/POST | Yes | "Token not provided" |
| `/wallet/receive` | GET | Yes | "Token not provided" |
| `/wallet/deposit` | GET | Yes | "Token not provided" |
| `/wallet/withdraw` | GET | Yes | "Token not provided" |

### api.novawallet.org — Auth Endpoints

| Endpoint | Status | Notes |
|----------|--------|-------|
| `/auth/line` | 302 → LINE OAuth | client_id: `2007849543` |
| `/auth/google` | 302 → Google OAuth | client_id: `720558249209-g50r30tn541u8422s5mjf2n9uciseudg.apps.googleusercontent.com` |
| `/auth/line/callback` | Exists | OAuth callback |
| `/auth/google/callback` | Exists | OAuth callback |

### app.novawallet.org — SPA Routes (from JS router)

```
/auth, /onboarding, /wallet, /wallet/pay/:qr?, /wallet/deposit,
/wallet/deposit/fiat, /wallet/deposit/rub, /wallet/deposit/network,
/wallet/deposit/asset/:id, /wallet/cashout, /wallet/cashout/guide,
/wallet/cashout/:id, /wallet/transfer, /wallet/transfer/:id,
/wallet/transfer/:id/confirm, /wallet/cashback, /txs, /friends,
/profile, /profile/settings, /profile/settings/pkey, /profile/lang,
/profile/region, /profile/legal, /profile/kyc
```

---

## Findings

### FINDING-01: Wildcard CORS on API

**Severity:** HIGH  
**CVSS 3.1:** 7.5 (AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N)

**Description:**  
`api.novawallet.org` returns `Access-Control-Allow-Origin: *` on all endpoints, including authenticated ones. Combined with `Access-Control-Allow-Methods: GET,HEAD,PUT,POST,DELETE,PATCH`, this allows any website to make cross-origin requests to the API.

For a financial/crypto wallet API, this means a malicious website could potentially:
- Make authenticated requests if the user has an active session
- Read wallet balance, transaction history, and potentially keys/seed phrases

**Note:** Since auth uses JWT Bearer tokens (not cookies), the actual exploitability depends on how tokens are stored client-side. If tokens are in localStorage, CORS alone won't leak them. However, if any cookie-based auth exists or tokens are somehow accessible, this is critical.

**Evidence:**
```
access-control-allow-origin: *
access-control-allow-methods: GET,HEAD,PUT,POST,DELETE,PATCH
```

**Recommendation:**  
- Restrict CORS to `https://app.novawallet.org` only
- Add `Access-Control-Allow-Credentials: false` explicitly
- Remove wildcard origin

---

### FINDING-02: Verbose JWT Error Messages

**Severity:** MEDIUM  
**CVSS 3.1:** 5.3 (AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N)

**Description:**  
The API returns detailed JWT validation error messages that reveal internal implementation details:

- No token: `"Token not provided"`
- Invalid token: `"invalid JWT token: invalid"`
- Valid structure, wrong key: `"token(eyJ...) signature mismatched"`

The signature mismatch error echoes back the full token, confirming the algorithm and structure expected by the server. This aids attackers in crafting valid-looking tokens.

**Evidence:**
```
curl -H "Authorization: Bearer eyJ..." → "token(eyJ...) signature mismatched"
```

**Recommendation:**  
- Return generic `"Unauthorized"` for all auth failures
- Do not echo back the token in error messages
- Log details server-side only

---

### FINDING-03: No Rate Limiting on API

**Severity:** MEDIUM  
**CVSS 3.1:** 5.3 (AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:L)

**Description:**  
20 rapid sequential requests to `/wallet/balance` all returned 401 with no rate limiting, throttling, or blocking. This allows:
- Brute-force attacks against auth endpoints
- Token enumeration
- DoS via request flooding

**Evidence:**
```
20 requests → all 401, no 429
```

**Recommendation:**  
- Implement rate limiting (e.g., 60 req/min per IP for unauthenticated, 120 for authenticated)
- Use Cloudflare Rate Limiting rules
- Add progressive delays for failed auth attempts

---

### FINDING-04: Sensitive Crypto Endpoints Exposed

**Severity:** MEDIUM  
**CVSS 3.1:** 5.3 (AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N)

**Description:**  
The API exposes `/wallet/keys`, `/wallet/seed`, and `/wallet/export` endpoints. While they require authentication (401), their mere existence raises concerns:

1. **Endpoint enumeration:** Attackers know exactly which endpoints to target
2. **Key/seed via API:** Private keys and seed phrases should ideally never traverse the network. A compromised JWT token would give full access to cryptographic material.
3. The frontend route `/profile/settings/pkey` confirms private key viewing is a feature.

**Recommendation:**  
- Evaluate if keys/seed need to be served via API at all (prefer client-side-only derivation)
- If required, add additional authentication (2FA, PIN, re-authentication)
- Rate limit these endpoints severely (e.g., 3 req/hour)
- Add audit logging for all access to these endpoints

---

### FINDING-05: Missing Security Headers on API

**Severity:** LOW  
**CVSS 3.1:** 3.7 (AV:N/AC:H/PR:N/UI:N/S:U/C:N/I:L/A:N)

**Description:**  
`api.novawallet.org` is missing standard security headers:

| Header | Status |
|--------|--------|
| Strict-Transport-Security | ❌ Missing |
| Content-Security-Policy | ❌ Missing |
| X-Content-Type-Options | ❌ Missing |
| X-Frame-Options | ❌ Missing |
| X-XSS-Protection | ❌ Missing |

**Recommendation:**  
Add security headers, at minimum:
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
```

---

### FINDING-06: OAuth Client IDs Exposed in Redirect URLs

**Severity:** INFO  
**CVSS 3.1:** 0.0

**Description:**  
OAuth client IDs are visible in auth redirect URLs. This is by design for OAuth2 flows and not a vulnerability per se, but worth noting:

- LINE client_id: `2007849543`
- Google client_id: `720558249209-g50r30tn541u8422s5mjf2n9uciseudg.apps.googleusercontent.com`
- Redirect URIs: `https://api.novawallet.org/auth/{provider}/callback`

**Recommendation:**  
- Ensure OAuth apps have strict redirect URI validation
- Verify Google Cloud Console restricts the client to expected origins only

---

### FINDING-07: Wildcard CORS on Frontend

**Severity:** LOW  
**CVSS 3.1:** 3.1 (AV:N/AC:H/PR:N/UI:R/S:U/C:L/I:N/A:N)

**Description:**  
`app.novawallet.org` also returns `Access-Control-Allow-Origin: *`. While the frontend is a static SPA, this allows any site to fetch its HTML/JS resources. Combined with the SPA catch-all routing (all paths return 200 with the same HTML), this is low risk but unnecessary.

**Recommendation:**  
Remove wildcard CORS from the frontend; static assets don't need it.

---

### FINDING-08: Admin Endpoint Discoverable

**Severity:** LOW  
**CVSS 3.1:** 3.7 (AV:N/AC:H/PR:N/UI:N/S:U/C:L/I:N/A:N)

**Description:**  
`/admin` returns 401 "Unauthorized" (distinct from 404 "Not found" on non-existent endpoints), confirming an admin panel exists. This aids targeted attacks.

**Recommendation:**  
- Return 404 for admin endpoints when accessed without valid admin credentials
- Move admin to a separate subdomain with IP allowlisting

---

### FINDING-09: novawallet.org .env WAF Rate Limiting

**Severity:** INFO  
**CVSS 3.1:** 0.0

**Description:**  
Requesting `https://novawallet.org/.env` returns HTTP 429 instead of 404, suggesting Cloudflare WAF is actively blocking sensitive file access attempts. This is **good security practice**.

**Recommendation:** None — working as expected.

---

### FINDING-10: Contentsquare/Hotjar Session Recording on Wallet App

**Severity:** LOW  
**CVSS 3.1:** 3.1 (AV:N/AC:H/PR:N/UI:R/S:U/C:L/I:N/A:N)

**Description:**  
The wallet SPA includes `https://t.contentsquare.net/uxa/ccc1e9d22f8f3.js` (Hotjar/Contentsquare), which records user sessions. On a crypto wallet app that handles private keys and seed phrases, session recording could potentially capture sensitive data.

**Recommendation:**  
- Ensure session recording excludes sensitive screens (pkey, seed, transfer confirmation)
- Configure Contentsquare to mask input fields and sensitive areas
- Consider removing session recording entirely from a financial crypto app

---

## Summary Table

| ID | Finding | Severity | CVSS |
|----|---------|----------|------|
| F-01 | Wildcard CORS on API | HIGH | 7.5 |
| F-02 | Verbose JWT Error Messages | MEDIUM | 5.3 |
| F-03 | No Rate Limiting on API | MEDIUM | 5.3 |
| F-04 | Sensitive Crypto Endpoints (keys/seed) via API | MEDIUM | 5.3 |
| F-05 | Missing Security Headers on API | LOW | 3.7 |
| F-06 | OAuth Client IDs Exposed | INFO | 0.0 |
| F-07 | Wildcard CORS on Frontend | LOW | 3.1 |
| F-08 | Admin Endpoint Discoverable | LOW | 3.7 |
| F-09 | .env WAF Protection (positive) | INFO | 0.0 |
| F-10 | Session Recording on Crypto Wallet | LOW | 3.1 |

---

## Scope Notes

- **GraphQL:** Not found on any subdomain
- **Source maps:** `.js.map` files return SPA HTML (not actual maps) — no source map exposure
- **Swagger/OpenAPI:** Not found
- **Stack traces:** No stack traces or debug info leaked
- **novawallet.org:** Tilda CMS landing page, no API endpoints, WAF active

---

*Report generated by 0xAudit — Edward*
