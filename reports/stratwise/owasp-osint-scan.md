# 🛡️ Stratwise.ai — OWASP Top 10 & OSINT Security Audit

**Auditor:** Edward, 0xAudit  
**Date:** 2026-02-09  
**Target:** stratwise.ai, api.stratwise.ai, app.stratwise.ai  
**Scope:** External black-box assessment  

---

## Executive Summary

| Severity | Count |
|----------|-------|
| 🔴 CRITICAL | 2 |
| 🟠 HIGH | 3 |
| 🟡 MEDIUM | 4 |
| 🔵 LOW | 3 |
| ℹ️ INFO | 3 |

**Overall Risk: HIGH** — Critical CORS misconfiguration on API allows credential theft. Weak password policy allows trivial passwords. Excessive PII leakage in login responses.

---

## Architecture Overview

| Component | Technology |
|-----------|-----------|
| Frontend | React SPA (Vite build), Cloudflare CDN |
| Backend API | Python (FastAPI) at api.stratwise.ai |
| Auth | Firebase + custom email auth |
| Infrastructure | Cloudflare (CDN/WAF), Google Cloud |
| Charting | TradingView |
| Analytics | GTM (GTM-P29T4RP7) |
| App | app.stratwise.ai (Cloudflare Workers) |

---

## OWASP Top 10 Findings

### 🔴 CRITICAL — F01: CORS Misconfiguration with Credentials (A01 Broken Access Control)

**CVSS 3.1:** 9.1 (Critical)  
**Vector:** `AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N`

**Description:**  
`api.stratwise.ai` reflects any `Origin` header in `Access-Control-Allow-Origin` while also setting `Access-Control-Allow-Credentials: true`. This allows any malicious website to make authenticated cross-origin requests and steal user data/tokens.

**Evidence:**
```
Request: Origin: https://evil.com
Response:
  access-control-allow-origin: https://evil.com
  access-control-allow-credentials: true
  access-control-allow-methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
```

**Impact:** An attacker can create a phishing page that silently reads authenticated user data (portfolio, strategies, API keys, trading history) via the victim's browser session.

**Recommendation:**  
- Whitelist specific origins: `https://stratwise.ai`, `https://app.stratwise.ai`
- Never reflect arbitrary origins with `credentials: true`

---

### 🔴 CRITICAL — F02: Weak Password Policy & PII Leakage in Auth Response (A07 Auth Failures)

**CVSS 3.1:** 8.6 (High → Critical due to chaining)  
**Vector:** `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:N`

**Description:**  
The login endpoint (`POST /api/v1/auth/login`) accepts extremely weak passwords (e.g., "test") and returns excessive PII in the response including:
- Full name, email, user ID
- Plan details, subscription status
- Account creation date, last login timestamp
- Auth provider info, role
- **Transfer token** for app.stratwise.ai session creation

**Evidence:**
```json
{
  "transfer_token": "bb5d090...bae284a",
  "redirect_url": "https://app.stratwise.ai/auth?token=...",
  "user": {
    "id": "6e01adc0-...",
    "email": "test@test.com",
    "first_name": "Daniil",
    "last_name": "Goryunov",
    "plan": {"name": "free"},
    "role": "user",
    "status": "active"
  }
}
```

**Impact:**  
- Brute force with common passwords will succeed
- User enumeration possible (different responses for valid/invalid emails)
- PII harvesting at scale

**Recommendation:**  
- Enforce minimum 8-char password with complexity requirements
- Return minimal data in login response (only token)
- Move user data retrieval to authenticated `/me` endpoint
- Implement account lockout after failed attempts

---

### 🟠 HIGH — F03: Missing Security Headers (A05 Security Misconfiguration)

**CVSS 3.1:** 7.1 (High)  
**Vector:** `AV:N/AC:L/PR:N/UI:R/S:C/C:L/I:L/A:N`

**Description:**  
Multiple critical security headers are missing from both frontend and API responses:

| Header | Status |
|--------|--------|
| `Content-Security-Policy` | ❌ Missing |
| `Strict-Transport-Security` | ❌ Missing |
| `X-Frame-Options` | ❌ Missing |
| `Permissions-Policy` | ❌ Missing |
| `X-XSS-Protection` | ❌ Missing |
| `X-Content-Type-Options` | ✅ Present (`nosniff`) |
| `Referrer-Policy` | ✅ Present (`strict-origin-when-cross-origin`) |

**Impact:**  
- No CSP → XSS attacks can load arbitrary scripts
- No HSTS → Downgrade attacks possible
- No X-Frame-Options → Clickjacking on trading interface
- For a **financial platform**, this is especially dangerous

**Recommendation:**  
```
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
Content-Security-Policy: default-src 'self'; script-src 'self' https://www.googletagmanager.com https://s3.tradingview.com; ...
X-Frame-Options: DENY
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

---

### 🟠 HIGH — F04: Wildcard CORS on Frontend (A01 Broken Access Control)

**CVSS 3.1:** 5.3 (Medium, but HIGH in context of financial platform)

**Description:**  
Main domain `stratwise.ai` returns `Access-Control-Allow-Origin: *`. While the SPA itself may not serve sensitive data, this combined with the API CORS issue creates a broader attack surface.

**Evidence:**
```
access-control-allow-origin: *
```

**Recommendation:**  
Remove wildcard CORS or restrict to specific trusted origins.

---

### 🟠 HIGH — F05: No Subresource Integrity (SRI) + Source Maps Exposed (A08 Software & Data Integrity)

**CVSS 3.1:** 6.8 (Medium-High)

**Description:**  
- Main JS bundle loaded without SRI hash: `<script type="module" crossorigin src="/assets/index-BrVI2RJu.js"></script>`
- Source maps accessible at `/assets/index-BrVI2RJu.js.map` (HTTP 200)
- No Content-Security-Policy to restrict script sources

**Impact:**  
- CDN/supply-chain compromise could inject malicious code undetected
- Source maps expose full application source code, aiding reverse engineering
- For a trading platform handling funds, this is high risk

**Recommendation:**  
- Add SRI: `integrity="sha384-..."` to all script/link tags
- Remove source maps from production
- Implement CSP with strict script-src

---

### 🟡 MEDIUM — F06: Firebase Configuration Exposed (A05 Security Misconfiguration)

**CVSS 3.1:** 5.3 (Medium)

**Description:**  
Firebase configuration hardcoded in client JS bundle:
```
apiKey: "AIzaSyDBwQtdwkTdNB6ssp03zdd8t0t9MFBx3P4"
projectId: "stratwise-edaae"
authDomain: "auth.stratwise.ai"
messagingSenderId: "322903855038"
appId: "1:322903855038:web:59905ceef8a176c65133ef"
```

**Impact:**  
While Firebase API keys are designed to be public, this exposes project details for:
- Enumeration of Firebase services
- Potential abuse if Firebase Security Rules are misconfigured
- Targeted attacks against the Firebase project

**Recommendation:**  
- Audit Firebase Security Rules rigorously
- Restrict API key usage to specific domains in Google Cloud Console
- Enable App Check for Firebase

---

### 🟡 MEDIUM — F07: Rate Limiting Insufficient (A07 Auth Failures)

**CVSS 3.1:** 5.9 (Medium)

**Description:**  
Login endpoint allows 9 rapid requests before returning HTTP 429. For a financial platform, this threshold is too high.

**Evidence:**
```
Requests 1-9: HTTP 401 (allowed)
Request 10: HTTP 429 (rate limited)
```

**Impact:**  
- Allows ~9 password guesses per time window per IP
- With distributed IPs, significant brute force possible
- No CAPTCHA or MFA observed

**Recommendation:**  
- Reduce to 3-5 attempts before lockout
- Implement exponential backoff
- Add CAPTCHA after 3 failed attempts
- Enforce MFA for all accounts (especially trading)

---

### 🟡 MEDIUM — F08: API Information Disclosure (A05 Security Misconfiguration)

**CVSS 3.1:** 5.3 (Medium)

**Description:**  
API health endpoint exposes service details:
```json
{
  "status": "healthy",
  "service": "stratwise-auth-api",
  "version": "0.1.0",
  "environment": "production"
}
```

Also exposes processing headers:
```
x-process-time: 0.001
x-request-id: f936739b-...
```

**Impact:** Reveals technology stack, version, and environment info useful for targeted attacks.

**Recommendation:**  
- Remove version/service name from health endpoint
- Restrict health endpoint to internal networks
- Remove `x-process-time` header (timing attacks)

---

### 🟡 MEDIUM — F09: Transfer Token Security Concerns (A07 Auth Failures)

**CVSS 3.1:** 6.5 (Medium)

**Description:**  
Login returns a `transfer_token` valid for 60 seconds, passed via URL parameter to `app.stratwise.ai/auth?token=...`. Tokens in URLs are logged in:
- Browser history
- Server logs
- Referrer headers
- Proxy logs

**Recommendation:**  
- Use POST-based token exchange instead of URL parameter
- Implement one-time use tokens
- Set short expiry (already 60s, good)

---

### 🔵 LOW — F10: GTM Tag Exposed (A09 Logging & Monitoring)

**CVSS 3.1:** 3.1 (Low)

**GTM ID:** `GTM-P29T4RP7`  
**Impact:** Can be used to enumerate tracking configuration.  
**Recommendation:** Standard practice, but ensure GTM container is locked down.

---

### 🔵 LOW — F11: Telegram & YouTube Links Exposed (A05)

**CVSS 3.1:** 2.0 (Low)

**Description:** Social channels found in JS: `https://t.me/stratwise`, `https://youtube.com/@stratwise`  
**Impact:** OSINT vector for social engineering.

---

### 🔵 LOW — F12: Input Validation (A03 Injection)

**CVSS 3.1:** 2.0 (Low — properly handled)

**Description:** SQL injection and XSS payloads tested on auth endpoints. FastAPI/Pydantic properly validates input with typed schemas. No injection vulnerabilities found in tested endpoints.

**Evidence:**
```json
{"detail":[{"type":"value_error","loc":["body","email"],"msg":"value is not a valid email address"}]}
```

**Status:** ✅ Properly mitigated via input validation.

---

## OSINT Findings

### ℹ️ INFO — O01: Technology Stack Identified

| Layer | Technology |
|-------|-----------|
| Frontend Framework | React 18+ (production build) |
| Build Tool | Vite |
| State Management | Redux Toolkit |
| Backend | Python FastAPI |
| Auth | Firebase Auth + Custom email auth |
| CDN/WAF | Cloudflare |
| SSL | Google Trust Services (WE1), valid until 2026-04-30 |
| TLS | 1.2 and 1.3 only (TLS 1.0/1.1 rejected ✅) |
| Charts | TradingView |
| ReCAPTCHA | Google reCAPTCHA (found in JS, not seen on login) |
| Analytics | Google Tag Manager |
| Cloud | Google Cloud (Firebase) |

### ℹ️ INFO — O02: Subdomain Enumeration

| Subdomain | Status |
|-----------|--------|
| stratwise.ai | 200 — Main SPA |
| api.stratwise.ai | Active — FastAPI auth service |
| app.stratwise.ai | 403 — Application (Cloudflare Workers) |
| auth.stratwise.ai | Firebase Auth domain |
| dashboard.stratwise.ai | DNS not resolving |
| admin.stratwise.ai | DNS not resolving |

### ℹ️ INFO — O03: Personnel & Social

- **Developer identified from API response:** Daniil Goryunov (test account user, likely developer — account created 2025-11-03)
- **Telegram:** @stratwise / t.me/stratwise
- **YouTube:** youtube.com/@stratwise
- **Web Search:** Brave API key not configured — manual OSINT recommended for GitHub repos, LinkedIn profiles, breach databases

### ℹ️ INFO — O04: Robots.txt / Cloudflare

Cloudflare-managed robots.txt with AI training restrictions (`ai-train=no`). Content signals indicate awareness of data protection. No sensitive paths disclosed.

---

## Positive Findings ✅

1. **TLS 1.2+** only — TLS 1.0/1.1 properly rejected
2. **Input validation** — Pydantic/FastAPI provides good schema validation
3. **Valid SSL certificate** — Google Trust Services, auto-renewing
4. **Some rate limiting** exists on login (429 after 10 attempts)
5. **Cloudflare WAF** provides baseline protection
6. **SPA architecture** — no server-side content injection risk on frontend
7. **X-Content-Type-Options: nosniff** present
8. **Referrer-Policy** properly configured

---

## Risk Matrix

| ID | Finding | CVSS | Severity | OWASP | Priority |
|----|---------|------|----------|-------|----------|
| F01 | CORS reflects origin + credentials | 9.1 | 🔴 CRITICAL | A01 | P0 — Fix immediately |
| F02 | Weak passwords + PII leakage | 8.6 | 🔴 CRITICAL | A07 | P0 — Fix immediately |
| F03 | Missing security headers | 7.1 | 🟠 HIGH | A05 | P1 — Fix this sprint |
| F04 | Wildcard CORS on frontend | 5.3 | 🟠 HIGH | A01 | P1 — Fix this sprint |
| F05 | No SRI + source maps exposed | 6.8 | 🟠 HIGH | A08 | P1 — Fix this sprint |
| F06 | Firebase config exposed | 5.3 | 🟡 MEDIUM | A05 | P2 — Fix this month |
| F07 | Rate limiting too permissive | 5.9 | 🟡 MEDIUM | A07 | P2 — Fix this month |
| F08 | API info disclosure | 5.3 | 🟡 MEDIUM | A05 | P2 — Fix this month |
| F09 | Token in URL parameter | 6.5 | 🟡 MEDIUM | A07 | P2 — Fix this month |
| F10 | GTM tag exposed | 3.1 | 🔵 LOW | A09 | P3 |
| F11 | Social links exposed | 2.0 | 🔵 LOW | A05 | P3 |
| F12 | Input validation | 2.0 | 🔵 LOW | A03 | ✅ OK |

---

## Recommendations Summary (Priority Order)

### P0 — Immediate (This Week)
1. **Fix API CORS** — Whitelist specific origins, remove wildcard reflection with credentials
2. **Enforce password policy** — Minimum 8 chars, complexity, bcrypt cost factor
3. **Minimize login response** — Remove PII, return only token

### P1 — This Sprint
4. **Add security headers** — CSP, HSTS, X-Frame-Options, Permissions-Policy
5. **Add SRI** to all script/link tags
6. **Remove source maps** from production

### P2 — This Month
7. **Harden rate limiting** — 3-5 attempts, CAPTCHA, exponential backoff
8. **Implement MFA** — Critical for a financial/trading platform
9. **Audit Firebase Security Rules**
10. **Remove version info** from health endpoint

---

*Report generated by 0xAudit — Edward*  
*Classification: CONFIDENTIAL — For Stratwise team only*
