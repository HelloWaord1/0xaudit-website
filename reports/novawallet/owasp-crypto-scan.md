# 🛡️ Security Audit Report: app.novawallet.org
## OWASP Top 10 & Crypto-Specific Assessment

**Auditor:** Edward, 0xAudit  
**Target:** https://app.novawallet.org  
**Date:** 2026-02-09  
**Version:** 3.10.1 (prod)  
**Type:** Web-based Crypto Wallet (PWA) — Thailand-focused payment gateway  
**API:** api.novawallet.org  
**Hosting:** Cloudflare  
**TLS:** ECDSA-SHA256, Google Trust Services (WE1), valid until 2026-04-28  

---

## Executive Summary

Nova Wallet is a **custodial-like web wallet** (PWA) for crypto payments, primarily targeting Thailand. Authentication is via OAuth (LINE, Google). Private keys exist server-side but are **exposed to the client** through the wallet object (`n.wallet.privateKey`). The application has **critical security misconfigurations** including wildcard CORS, missing CSP, no SRI, and session replay tracking (Hotjar/ContentSquare) on a financial application.

**Critical:** 2 | **High:** 4 | **Medium:** 5 | **Low:** 3

---

## OWASP Top 10 Findings

### A01: Broken Access Control

#### [CRITICAL] CORS Wildcard on Crypto Wallet API
- **Header:** `Access-Control-Allow-Origin: *`
- **CVSS:** 9.1 (Critical)
- **Description:** The application returns `Access-Control-Allow-Origin: *` on all responses. Any malicious website can make cross-origin requests to app.novawallet.org. Combined with token-in-URL patterns (OAuth callback), this enables cross-origin data theft.
- **Evidence:** `curl -sI https://app.novawallet.org` → `access-control-allow-origin: *`
- **Impact:** An attacker's website can read wallet data, initiate transfers, or steal tokens via cross-origin requests.
- **Recommendation:** Restrict CORS to specific trusted origins. Use `Access-Control-Allow-Credentials` carefully. Implement strict origin validation.

#### [HIGH] Token Passed via URL Query Parameters
- **CVSS:** 7.5 (High)
- **Description:** OAuth callback passes tokens via URL: `window.location.search → token`. The `index.js` reads `p.get("token")` from URL params and sends it via `postMessage`. Tokens in URLs leak via Referer headers, browser history, server logs, and analytics.
- **Evidence:** `var s=p.get("token"); s&&window.opener?.postMessage({token:s},location.origin)`
- **Recommendation:** Use HTTP-only cookies or POST-based token exchange. Never transmit tokens via URL parameters.

#### [MEDIUM] No X-Frame-Options / frame-ancestors
- **CVSS:** 5.4 (Medium)
- **Description:** No `X-Frame-Options` or `Content-Security-Policy: frame-ancestors` header. The wallet can be embedded in malicious iframes for clickjacking attacks.
- **Recommendation:** Add `X-Frame-Options: DENY` and `Content-Security-Policy: frame-ancestors 'none'`.

---

### A02: Cryptographic Failures

#### [CRITICAL] Private Key Exposed to Client-Side JavaScript
- **CVSS:** 9.8 (Critical)
- **Description:** The private key is accessible via the client-side wallet object `n.wallet.privateKey` and rendered directly in a pkey-page component. Any XSS vulnerability, malicious browser extension, or compromised JS dependency can steal private keys.
- **Evidence (pkey-AWLDCZKO.js):**
  ```javascript
  <input type=${p?"password":"text"} readonly value=${n.wallet.privateKey} />
  // Copy button:
  d.copy(n.wallet.privateKey)
  ```
- **Impact:** Complete compromise of all user wallets. Private key theft leads to irreversible fund loss.
- **Recommendation:** 
  - Never expose raw private keys to the browser DOM
  - Use hardware security modules (HSM) or secure enclaves
  - If key export is needed, require 2FA + rate limiting + encryption
  - Consider moving to a fully custodial model where keys never leave the server

#### [HIGH] Token Stored in localStorage
- **CVSS:** 7.5 (High)
- **Description:** Auth token is stored in `localStorage.setItem("token", t)`. localStorage is accessible to any JavaScript running on the same origin, making it vulnerable to XSS-based token theft.
- **Evidence:** `localStorage.setItem("token",t)` in chunk-FCPXZ6SO.js
- **Recommendation:** Use HTTP-only, Secure, SameSite cookies for session management.

---

### A03: Injection (XSS)

#### [HIGH] No Content Security Policy
- **CVSS:** 8.1 (High)
- **Description:** No CSP header is set. Combined with: (a) private keys in the DOM, (b) tokens in localStorage, (c) no SRI on scripts — any XSS vector leads to complete wallet compromise.
- **Evidence:** Response headers contain no `Content-Security-Policy` header.
- **Recommendation:** Implement strict CSP: `script-src 'self'; style-src 'self' 'unsafe-inline'; connect-src 'self' https://api.novawallet.org; frame-ancestors 'none'`

---

### A04: Insecure Design

#### [HIGH] Client-Side Transfer Authorization
- **CVSS:** 7.5 (High)
- **Description:** Transfer confirmation happens client-side with `k.wallet.transfer(t,n,m)` called directly from the confirm page component. The wallet object holds the private key client-side and likely signs transactions in the browser. There's no visible 2FA, PIN, or biometric confirmation for transfers.
- **Evidence (confirm-CEDIRFWJ.js):**
  ```javascript
  async function*o(){ yield 1, await k.wallet.transfer(t,n,m) }
  ```
- **Impact:** If an attacker gains access to the session token, they can transfer all funds without additional verification.
- **Recommendation:**
  - Require PIN/biometric/2FA for every transfer
  - Implement server-side transaction signing with approval flow
  - Add transfer limits with cooling periods
  - Implement velocity checks and anomaly detection

#### [MEDIUM] OAuth-Only Authentication with No MFA
- **CVSS:** 5.9 (Medium)
- **Description:** Authentication relies solely on LINE and Google OAuth. No additional MFA, PIN, or biometric verification for accessing the wallet or performing transactions.
- **Recommendation:** Add mandatory 2FA/PIN for wallet access and transactions.

---

### A05: Security Misconfiguration

#### [MEDIUM] Missing Security Headers
- **CVSS:** 5.3 (Medium)
- **Missing Headers:**
  - `Content-Security-Policy` — **MISSING** ⛔
  - `X-Frame-Options` — **MISSING** ⛔
  - `Strict-Transport-Security` — **MISSING** ⛔
  - `Permissions-Policy` — **MISSING** ⛔
  - `Cross-Origin-Opener-Policy` — **MISSING** ⛔
  - `Cross-Origin-Resource-Policy` — **MISSING** ⛔
- **Present:**
  - `X-Content-Type-Options: nosniff` ✅
  - `Referrer-Policy: strict-origin-when-cross-origin` ✅
- **Recommendation:** Add all missing security headers. HSTS is especially critical for a financial application.

#### [LOW] Service Worker Caches Sensitive Assets
- **CVSS:** 3.7 (Low)
- **Description:** The service worker (`sw.js`) caches JavaScript bundles and assets. If the device is compromised, cached wallet logic persists.
- **Recommendation:** Exclude sensitive JS from SW cache. Add cache expiry.

---

### A06: Vulnerable & Outdated Components

#### [MEDIUM] Session Replay / Analytics on Crypto Wallet
- **CVSS:** 6.5 (Medium)
- **Description:** The wallet loads **Hotjar / ContentSquare** tracking (`t.contentsquare.net/uxa/ccc1e9d22f8f3.js`) AND includes a full **rrweb session replay SDK** (Gleap) in the main JS bundle. Session replay on a crypto wallet captures:
  - Private key display (pkey page)
  - Transaction amounts and addresses
  - User interaction patterns
  - Potentially wallet balances
- **Evidence:** `<script src=https://t.contentsquare.net/uxa/ccc1e9d22f8f3.js></script>` in HTML; rrweb session recording SDK in chunk-FCPXZ6SO.js (728KB bundle).
- **Impact:** Private keys could be recorded and transmitted to third-party analytics servers.
- **Recommendation:** **Immediately remove** all session replay and analytics from the wallet. If needed, implement server-side analytics only. Never record screens where private keys or sensitive data are displayed.

#### [MEDIUM] Large Third-Party JS Bundle (Gleap)
- **CVSS:** 5.3 (Medium)
- **Description:** The main chunk (chunk-FCPXZ6SO.js, 728KB) contains the Gleap feedback SDK with full rrweb recording, PostCSS parser, and screen capture capabilities. This massively increases attack surface.
- **Recommendation:** Remove or isolate third-party feedback tools. Use a separate, sandboxed domain for non-critical tools.

---

### A07: Identification & Authentication Failures

#### [LOW] No Session Expiry Visible
- **CVSS:** 3.9 (Low)
- **Description:** Token is stored persistently in localStorage with no visible expiry mechanism. Sessions appear to persist indefinitely.
- **Recommendation:** Implement token expiry, refresh token rotation, and idle timeout.

---

### A08: Software & Data Integrity Failures

#### [HIGH] No Subresource Integrity (SRI)
- **CVSS:** 7.4 (High)
- **Description:** No SRI hashes on any scripts, including the third-party ContentSquare/Hotjar script loaded from external CDN. If the CDN is compromised, arbitrary code executes in the wallet context with access to private keys.
- **Evidence:** `<script src=https://t.contentsquare.net/uxa/ccc1e9d22f8f3.js></script>` — no `integrity` attribute.
- **Recommendation:** Add SRI to ALL script tags. Pin third-party dependencies. Consider self-hosting critical scripts.

---

### A09: Security Logging & Monitoring Failures

#### [LOW] No Visible Client-Side Security Monitoring
- **CVSS:** 3.0 (Low)
- **Description:** No evidence of CSP violation reporting, client-side error monitoring for security events, or anomaly detection.
- **Recommendation:** Implement CSP with `report-uri`, add client-side security event logging, monitor for unusual transfer patterns.

---

### A10: Server-Side Request Forgery (SSRF)

#### [INFO] Protocol Handlers Registered
- **Description:** The manifest registers custom protocol handlers: `web+nova` and `web+ethereum` → `/wallet/transfer?input=%s`. While not directly SSRF, malicious protocol URLs could be crafted to auto-fill transfer forms.
- **Recommendation:** Strictly validate and sanitize all input from protocol handlers.

---

## Crypto-Specific Findings

### Private Key Storage
- **Location:** Server-generated, transmitted to client via API, stored in client-side JS wallet object
- **Exposure:** Directly accessible as `n.wallet.privateKey`, rendered in DOM on pkey page
- **Risk:** CRITICAL — Any XSS, malicious extension, or analytics tool can exfiltrate keys

### Seed Phrase Handling
- **Status:** No seed phrase/mnemonic detected in client code
- **Architecture:** Appears custodial — wallet created server-side, key provided to client
- **Note:** No BIP39/BIP32/HDKey libraries found in JS bundles

### Transaction Signing
- **Location:** Client-side via `wallet.transfer()` method
- **Flow:** Confirm page → `k.wallet.transfer(address, assetId, amount)`
- **Wallet Class:** Custom `Gi` class instantiated with auth token
- **Risk:** No visible client-side signing with private key; transfers likely authorized via API token

### Key Architecture Summary
```
OAuth (LINE/Google) → API Token → localStorage
API Token → Wallet Object (includes privateKey)
Transfer → API call with token auth (server executes)
Private Key → Viewable/copyable on /profile/settings/pkey
```

---

## OSINT Findings

⚠️ **Web search unavailable** (no Brave API key configured). Manual OSINT notes:
- Domain: novawallet.org — registered for Thailand crypto payments
- No public GitHub repos found in JS source
- No known CVE database entries found
- **Note:** "Nova Wallet" name conflicts with the well-known Polkadot ecosystem wallet (novawallet.io) — potential brand confusion / phishing risk

---

## Risk Summary Table

| # | Finding | CVSS | Severity | Category |
|---|---------|------|----------|----------|
| 1 | Private Key Exposed to Client JS | 9.8 | CRITICAL | A02 / Crypto |
| 2 | CORS Wildcard `*` | 9.1 | CRITICAL | A01 |
| 3 | No Content Security Policy | 8.1 | HIGH | A03 |
| 4 | Token in URL Parameters | 7.5 | HIGH | A01 |
| 5 | Token in localStorage | 7.5 | HIGH | A02 |
| 6 | Client-Side Transfer, No 2FA | 7.5 | HIGH | A04 |
| 7 | No SRI on External Scripts | 7.4 | HIGH | A08 |
| 8 | Session Replay on Crypto Wallet | 6.5 | MEDIUM | A06 |
| 9 | OAuth-Only, No MFA | 5.9 | MEDIUM | A04/A07 |
| 10 | Missing Security Headers | 5.3 | MEDIUM | A05 |
| 11 | Large Third-Party Bundle | 5.3 | MEDIUM | A06 |
| 12 | No X-Frame-Options | 5.4 | MEDIUM | A01 |
| 13 | No Session Expiry | 3.9 | LOW | A07 |
| 14 | SW Caches Sensitive Assets | 3.7 | LOW | A05 |
| 15 | No Security Monitoring | 3.0 | LOW | A09 |

---

## Priority Remediation

### Immediate (P0 — Do Now)
1. **Remove session replay / analytics** (Hotjar, Gleap/rrweb) from wallet
2. **Fix CORS** — restrict to specific origins
3. **Add CSP header** with strict policy
4. **Remove private key from client-side DOM** — redesign key export flow

### Short-term (P1 — This Week)
5. Move token to HTTP-only cookies
6. Add SRI to all scripts
7. Implement 2FA/PIN for transfers
8. Add missing security headers (HSTS, X-Frame-Options, COOP, CORP)

### Medium-term (P2 — This Month)
9. Implement server-side transaction signing with approval workflow
10. Add session expiry and token rotation
11. Set up CSP violation reporting
12. Security audit of api.novawallet.org endpoints

---

*Report generated by Edward @ 0xAudit | External black-box assessment | No exploitation attempted*
