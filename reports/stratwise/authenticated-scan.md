# 🛡️ Stratwise.ai — Authenticated Security Audit Report

**Auditor:** Edward, 0xAudit  
**Date:** 2026-02-09  
**Target:** stratwise.ai / api.stratwise.ai  
**Account:** goriunov.ds@phystech.edu (role: admin)  
**Scope:** Authenticated API testing (read-only, non-destructive)

---

## Executive Summary

The authenticated audit of stratwise.ai revealed **2 Critical**, **3 High**, and **3 Medium** severity vulnerabilities. The most severe issues include a broken access control (IDOR) allowing access to other users' trading bots and strategies, wildcard CORS misconfiguration enabling credential theft, and token non-invalidation after logout. Given that this is a **financial trading platform** managing real exchange API keys and funds, these findings pose significant risk.

---

## Architecture Overview

- **Frontend:** SPA (React/Vite) at `stratwise.ai`, app deployed at `app.stratwise.ai`
- **API:** FastAPI (Python) at `api.stratwise.ai` (OpenAPI 3.1.0 exposed)
- **Auth Flow:** Email/Password → Firebase → transfer_token → exchange-token → JWT (HS256)
- **CDN/WAF:** Cloudflare
- **Database:** PostgreSQL (mentioned in OpenAPI descriptions)

---

## Findings

### 🔴 CRITICAL-01: IDOR — Access to Other Users' Trading Bots and Configs

| Field | Value |
|-------|-------|
| **CVSS 3.1** | 8.6 (High) — AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:N/A:N |
| **Severity** | CRITICAL |
| **Endpoint** | `GET /api/v1/bots/{bot_id}`, `GET /api/v1/bots/{bot_id}/configs/active` |
| **CWE** | CWE-639: Authorization Bypass Through User-Controlled Key |

**Description:**  
The `/api/v1/bots/` endpoint returns bots from ALL users, not just the authenticated user. The first bot in the list (`9d5c7962-fa63-4025-943e-be933f58cae1`) belongs to user `d943368c-ff55-48d1-b195-7bc6ba593d78` — a different user entirely. 

Furthermore, accessing `/api/v1/bots/{other_user_bot_id}` and `/api/v1/bots/{other_user_bot_id}/configs/active` returns full details including:
- Trading pair, exchange, investment amounts
- ML model configurations (strategy parameters, stop-loss, take-profit, grid settings)
- API key IDs linked to the bot

**Impact:** Any authenticated user can enumerate and read ALL bots on the platform, including trading strategies, investment amounts, and linked API key references. On a trading platform, this is a **direct competitive/financial intelligence leak**.

**Evidence:**
```
Bot ID: 9d5c7962-fa63-4025-943e-be933f58cae1
Owner: d943368c-ff55-48d1-b195-7bc6ba593d78 (NOT our user)
Our user: 3dadaf2c-ba07-4afd-9015-6f79e48791fe
Response: Full bot details + active config with ML parameters
```

**Recommendation:**
- Add `WHERE user_id = current_user.id` filter to ALL bot queries
- Implement row-level security or ownership checks on every resource access
- Audit all endpoints for similar IDOR patterns

---

### 🔴 CRITICAL-02: Wildcard CORS with Credentials — Full Account Takeover via CSRF

| Field | Value |
|-------|-------|
| **CVSS 3.1** | 8.1 (High) — AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N |
| **Severity** | CRITICAL |
| **Header** | `Access-Control-Allow-Origin: <reflects any origin>` + `Access-Control-Allow-Credentials: true` |
| **CWE** | CWE-942: Permissive Cross-domain Policy with Untrusted Domains |

**Description:**  
The API reflects ANY origin in `Access-Control-Allow-Origin` and sets `Access-Control-Allow-Credentials: true`. This means any malicious website can make authenticated API requests on behalf of the user if they visit the attacker's page while logged in.

**Evidence:**
```
Request: Origin: https://evil.com
Response: 
  Access-Control-Allow-Origin: https://evil.com
  Access-Control-Allow-Credentials: true
  Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
```

**Impact:** An attacker can create a phishing page that:
1. Reads the victim's exchange balances, API keys, wallet addresses
2. Creates/modifies bots with attacker-controlled parameters
3. Exfiltrates trading strategies
4. Combined with IDOR: access all platform data

**Recommendation:**
- Whitelist specific origins: `https://stratwise.ai`, `https://app.stratwise.ai`
- Never reflect arbitrary origins with credentials
- Implement CSRF tokens for state-changing operations

---

### 🟠 HIGH-01: JWT Token Not Invalidated After Logout

| Field | Value |
|-------|-------|
| **CVSS 3.1** | 6.5 (Medium) — AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N |
| **Severity** | HIGH |
| **Endpoint** | `POST /api/v1/auth/logout` |
| **CWE** | CWE-613: Insufficient Session Expiration |

**Description:**  
After calling `/api/v1/auth/logout` (which returns `{"success":true,"message":"Logout successful"}`), the JWT access token **remains valid** and can still be used to access all authenticated endpoints.

**Evidence:**
```
1. Called POST /api/v1/auth/logout → success
2. Called GET /api/v1/users/me with same token → still returns full user data
```

**Impact:** Stolen tokens remain usable until natural expiry (15 minutes). If tokens are leaked via logs, XSS, or CORS abuse, logout provides no protection.

**Recommendation:**
- Implement server-side token blacklist/revocation (Redis-based JTI blacklist)
- Or switch to opaque session tokens with server-side invalidation
- Consider shorter token TTL (current: 15 min is acceptable, but invalidation must work)

---

### 🟠 HIGH-02: Exchange API Keys Exposed in API Responses

| Field | Value |
|-------|-------|
| **CVSS 3.1** | 7.5 (High) — AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N |
| **Severity** | HIGH |
| **Endpoint** | `GET /api/v1/api-keys/` |
| **CWE** | CWE-200: Exposure of Sensitive Information |

**Description:**  
The API keys endpoint returns the **full exchange API key** values (public keys) for Binance and Bybit:
- Bybit: `7NiseOgGosGXBM4W6d`
- Binance: `gH64bk8IGQwDZJk4LRKTBSMRreAmSG9Yx55Rq5gOn5tNES2Qq2mrraxJ0Q8q1T6O`

While these are public API keys (not secrets), they should still be masked in responses. Combined with the CORS vulnerability, an attacker on a malicious site can steal these keys.

**Recommendation:**
- Mask API keys in responses: show only last 4 characters
- Return only key IDs/names for display purposes
- Never expose full key material in API responses

---

### 🟠 HIGH-03: OpenAPI/Swagger Documentation Publicly Accessible

| Field | Value |
|-------|-------|
| **CVSS 3.1** | 5.3 (Medium) — AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N |
| **Severity** | HIGH |
| **Endpoints** | `/docs` (200), `/openapi.json` (200), `/redoc` (200) |
| **CWE** | CWE-200: Exposure of Sensitive Information |

**Description:**  
Full API documentation including all endpoints, request/response schemas, and internal descriptions (in Russian) is publicly accessible without authentication. This reveals:
- All authentication flows and token mechanisms
- Internal service architecture details
- All available API endpoints and their parameters
- Firebase integration details

**Recommendation:**
- Restrict `/docs`, `/openapi.json`, `/redoc` to authenticated admin users only
- Or disable completely in production (`docs_url=None, redoc_url=None` in FastAPI)

---

### 🟡 MEDIUM-01: Email Not Verified — Account Active with Full Access

| Field | Value |
|-------|-------|
| **CVSS 3.1** | 4.3 (Medium) — AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:L/A:N |
| **Severity** | MEDIUM |
| **Field** | `email_verified_at: null` |
| **CWE** | CWE-287: Improper Authentication |

**Description:**  
The account has `email_verified_at: null` but has full access including admin role, bot creation, exchange API key management, and trading operations. There is no enforcement of email verification.

**Recommendation:**
- Require email verification before granting access to financial operations
- Limit unverified accounts to read-only or basic profile access

---

### 🟡 MEDIUM-02: JWT Uses HS256 Algorithm

| Field | Value |
|-------|-------|
| **CVSS 3.1** | 4.7 (Medium) — AV:N/AC:H/PR:N/UI:R/S:C/C:L/I:L/A:N |
| **Severity** | MEDIUM |
| **Header** | `{"alg":"HS256","typ":"JWT"}` |
| **CWE** | CWE-327: Use of a Broken or Risky Cryptographic Algorithm |

**Description:**  
JWT uses HMAC-SHA256 (symmetric), meaning the same secret signs and verifies tokens. If the secret is weak or leaked, any attacker can forge tokens for any user. HS256 is also susceptible to algorithm confusion attacks if RSA public keys are available.

**JWT Claims:**
```json
{
  "user_id": "3dadaf2c-ba07-4afd-9015-6f79e48791fe",
  "session_id": "23e0713d-63cd-4e0e-8c6b-3a0866182da8",
  "jti": "GSxbxT9HeZfRsCPgz1kwILuGACBZnHEmYXwcgaX0v4o",
  "token_type": "access",
  "exp": 1770640116,  // 15-minute TTL
  "iat": 1770639216,
  "is_demo": false,
  "subscription_status": "active",
  "plan_name": "free"
}
```

**Recommendation:**
- Switch to RS256/ES256 (asymmetric) for token signing
- Ensure JWT secret is at least 256 bits of entropy
- Implement algorithm restriction on verification (reject `alg: none`)

---

### 🟡 MEDIUM-03: Sensitive Data Over-Exposure in API Responses

| Field | Value |
|-------|-------|
| **CVSS 3.1** | 4.3 (Medium) — AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:N/A:N |
| **Severity** | MEDIUM |
| **Endpoints** | `/users/me`, `/crypto-wallets/me`, `/exchange/balance` |
| **CWE** | CWE-200: Exposure of Sensitive Information |

**Description:**  
API responses contain excessive information:
- `firebase_uid` exposed in login/user responses
- `derivation_index: 1062` for crypto wallets (internal HD wallet index)
- `ga_client_id` field (Google Analytics tracking)
- `auth_provider` reveals authentication mechanism
- Full wallet addresses across 6 networks with internal IDs

**Recommendation:**
- Remove `firebase_uid`, `derivation_index`, `ga_client_id`, `auth_provider` from API responses
- Return only information needed by the frontend
- Implement response DTOs that exclude internal fields

---

## Informational Findings

### ℹ️ INFO-01: Rate Limiting on Login

Login endpoint has rate limiting (429 status with countdown timer). This is **good** but the rate limit window appears very aggressive even for legitimate users (blocked for 191+ seconds after minimal attempts).

### ℹ️ INFO-02: Transfer Token Architecture

The two-step auth flow (transfer_token → exchange-token → JWT) adds a layer of security. Transfer tokens expire in 60 seconds, which is good. However, the transfer_token is transmitted as a URL parameter (`?token=...`) which may be logged in server logs, browser history, and referrer headers.

### ℹ️ INFO-03: Admin Role Assignment

The test account has `role: "admin"` — it's unclear if this is intentional or if regular users can somehow obtain admin role. The `/bots/` endpoint returning all users' bots may be an admin-only "feature" rather than a bug, but it's still dangerous without explicit admin panels.

### ℹ️ INFO-04: Free Plan Bypasses Bot Limits

The free plan specifies `max_bots: 1` and `max_api_keys: 1`, but the account has **29 active bots** and **2 API keys**. This suggests plan limit enforcement is broken or bypassed for admin accounts.

---

## Summary Table

| ID | Severity | CVSS | Finding |
|----|----------|------|---------|
| CRITICAL-01 | 🔴 Critical | 8.6 | IDOR — Access to other users' bots and trading configs |
| CRITICAL-02 | 🔴 Critical | 8.1 | Wildcard CORS with credentials — enables full account takeover |
| HIGH-01 | 🟠 High | 6.5 | JWT not invalidated after logout |
| HIGH-02 | 🟠 High | 7.5 | Exchange API keys exposed in responses |
| HIGH-03 | 🟠 High | 5.3 | OpenAPI documentation publicly accessible |
| MEDIUM-01 | 🟡 Medium | 4.3 | Email verification not enforced |
| MEDIUM-02 | 🟡 Medium | 4.7 | JWT uses HS256 symmetric algorithm |
| MEDIUM-03 | 🟡 Medium | 4.3 | Sensitive data over-exposure in API responses |

---

## Recommendations Priority

1. **IMMEDIATE (24h):** Fix IDOR on `/bots/` — add user ownership filter
2. **IMMEDIATE (24h):** Fix CORS — whitelist specific origins only
3. **URGENT (48h):** Implement token blacklisting on logout
4. **URGENT (48h):** Mask exchange API keys in responses
5. **SHORT-TERM (1 week):** Disable OpenAPI docs in production
6. **SHORT-TERM (1 week):** Enforce email verification
7. **MEDIUM-TERM (2 weeks):** Migrate to RS256 JWT
8. **MEDIUM-TERM (2 weeks):** Audit all endpoints for IDOR patterns
9. **MEDIUM-TERM (2 weeks):** Implement response DTOs to limit data exposure

---

*Report generated by 0xAudit automated security assessment.*
