# 🛡️ Web Application Security Audit — app.novawallet.org

**Auditor:** Edward, 0xAudit  
**Date:** 2026-02-09  
**Target:** https://app.novawallet.org  
**Type:** Crypto Wallet (PWA) — Payment Gateway (Thailand-focused)  
**Infrastructure:** Cloudflare CDN, Google Trust Services SSL  

---

## Executive Summary

Nova Wallet is a Progressive Web App (PWA) crypto payment gateway behind Cloudflare. The application has several **critical and high-severity** security header gaps that are especially dangerous for a crypto wallet handling private keys and financial transactions.

| Severity | Count |
|----------|-------|
| 🔴 Critical | 2 |
| 🟠 High | 3 |
| 🟡 Medium | 3 |
| 🔵 Low | 2 |
| ℹ️ Info | 3 |

---

## Findings

### 🔴 CRITICAL

#### F-01: Wildcard CORS — Access-Control-Allow-Origin: *
- **CVSS:** 9.1 (Critical)
- **Header:** `access-control-allow-origin: *`
- **Description:** The server responds with `Access-Control-Allow-Origin: *` for ALL requests, including from arbitrary origins (tested with `Origin: https://evil.com`). For a **crypto wallet**, this is catastrophic — any malicious website can make cross-origin requests to the app's API endpoints, potentially:
  - Stealing wallet data, session tokens, or cached keys
  - Reading sensitive responses (balances, transaction history, addresses)
  - Performing CSRF-like attacks against wallet operations
- **Recommendation:**
  - Replace `*` with an explicit allowlist of trusted origins
  - Implement proper CORS validation: check Origin header, respond only for approved domains
  - Never use wildcard CORS on applications handling financial/crypto data
  - Add `Vary: Origin` header

#### F-02: Missing Content-Security-Policy (CSP)
- **CVSS:** 8.8 (Critical)
- **Header:** MISSING
- **Description:** No CSP header detected. For a crypto wallet, this means:
  - No protection against XSS attacks that could steal private keys/seed phrases
  - Injected scripts can exfiltrate wallet data to attacker-controlled servers
  - Third-party scripts (contentsquare analytics already loaded) can be compromised in supply-chain attacks
  - No restriction on `eval()`, inline scripts, or data URIs
- **Recommendation:**
  - Implement strict CSP: `default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self' https://api.novawallet.org; img-src 'self' data:; frame-ancestors 'none';`
  - Use nonces or hashes instead of `'unsafe-inline'`
  - Remove `eval()` usage and avoid `'unsafe-eval'`
  - Add `report-uri` for CSP violation monitoring

---

### 🟠 HIGH

#### F-03: Missing X-Frame-Options
- **CVSS:** 7.5 (High)
- **Header:** MISSING
- **Description:** No `X-Frame-Options` header. The wallet app can be embedded in iframes on any site, enabling:
  - **Clickjacking attacks** — user tricked into clicking "Send" or "Approve Transaction" buttons
  - Overlay attacks on wallet signing dialogs
- **Recommendation:**
  - Add `X-Frame-Options: DENY`
  - Also add CSP `frame-ancestors 'none'`

#### F-04: Missing Permissions-Policy
- **CVSS:** 6.8 (High)
- **Header:** MISSING
- **Description:** No Permissions-Policy header. Browser features like camera, microphone, geolocation are not restricted. Malicious scripts could:
  - Access clipboard (where users copy wallet addresses/seed phrases)
  - Use camera for QR code phishing
- **Recommendation:**
  - Add `Permissions-Policy: camera=(), microphone=(), geolocation=(), clipboard-read=(), clipboard-write=(self)`

#### F-05: Third-Party Analytics on Crypto Wallet (Contentsquare)
- **CVSS:** 7.2 (High)
- **Script:** `https://t.contentsquare.net/uxa/ccc1e9d22f8f3.js`
- **Description:** A third-party analytics/session replay script (Contentsquare) is loaded on a crypto wallet app. This script can:
  - Record all user interactions including typing seed phrases
  - Capture screen content showing private keys, balances, addresses
  - Be compromised in a supply-chain attack to inject malicious code
  - Exfiltrate sensitive data to third-party servers
- **Recommendation:**
  - **Remove session replay/analytics from wallet pages entirely**
  - If analytics needed, use privacy-respecting, self-hosted solution
  - At minimum, exclude sensitive pages (key generation, seed phrase display, transaction signing)

---

### 🟡 MEDIUM

#### F-06: Missing X-XSS-Protection
- **CVSS:** 5.3 (Medium)
- **Header:** MISSING
- **Description:** Legacy `X-XSS-Protection` header not set. While modern browsers deprecate it, older browsers lose this protection layer.
- **Recommendation:** Add `X-XSS-Protection: 0` (to avoid false positives) or rely on CSP

#### F-07: Missing Strict-Transport-Security (HSTS)
- **CVSS:** 5.9 (Medium)
- **Header:** MISSING
- **Description:** No HSTS header detected. Users can be downgraded to HTTP via MITM attacks, especially dangerous for wallet transactions.
- **Recommendation:**
  - Add `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
  - Submit to HSTS preload list

#### F-08: Development Subdomain Exposed
- **CVSS:** 5.3 (Medium)
- **Subdomain:** `dev.novawallet.org` — HTTP 200 (live)
- **Description:** Development environment publicly accessible. May contain debug features, test accounts, or less hardened configurations.
- **Recommendation:**
  - Restrict `dev.novawallet.org` behind VPN or IP allowlist
  - Add authentication layer

---

### 🔵 LOW

#### F-09: Short-lived SSL Certificate
- **CVSS:** 2.1 (Low)
- **Details:** Certificate valid only 90 days (2026-01-28 to 2026-04-28), issued by Google Trust Services (WE1). Auto-renewal via Cloudflare likely, but short window increases risk of expiration.
- **Recommendation:** Verify auto-renewal is configured and monitored

#### F-10: Cache-Control Allows Public Caching
- **CVSS:** 2.4 (Low)
- **Header:** `cache-control: public, max-age=0, must-revalidate`
- **Description:** While `max-age=0` forces revalidation, `public` allows intermediate caches to store responses. For wallet data, this should be `private, no-store`.
- **Recommendation:** Use `Cache-Control: private, no-store, no-cache` for pages containing sensitive data

---

### ℹ️ INFORMATIONAL

#### I-01: Technology Stack
| Component | Value |
|-----------|-------|
| CDN/WAF | Cloudflare |
| TLS | TLSv1.3, TLS_AES_256_GCM_SHA384 |
| Certificate | Google Trust Services (WE1), CN=app.novawallet.org |
| App Type | PWA (Progressive Web App) |
| Framework | Custom SPA (vanilla/modern JS, `type=module`) |
| Analytics | Contentsquare UXA |
| Theme | #d0ff00 (green-yellow) |

#### I-02: Subdomains Discovered (via crt.sh)
| Subdomain | Status | Notes |
|-----------|--------|-------|
| app.novawallet.org | 200 | Main app |
| dev.novawallet.org | 200 | ⚠️ Dev environment exposed |
| docs.novawallet.org | 200 | Documentation |
| api.novawallet.org | 200 | API endpoint |
| www.novawallet.org | 301 | Redirects |
| my.novawallet.org | 522 | Connection error |
| staging.novawallet.org | N/A | Not resolving |
| *.novawallet.org | — | Wildcard cert in CT logs |

#### I-03: Positive Security Controls
- ✅ `referrer-policy: strict-origin-when-cross-origin` — Good
- ✅ `x-content-type-options: nosniff` — Good  
- ✅ TLSv1.3 with strong cipher — Excellent
- ✅ Cloudflare WAF/DDoS protection — Good
- ✅ No cookies set (client-side state management) — Reduces cookie attack surface
- ✅ No sitemap.xml exposed — Good
- ✅ robots.txt blocks AI crawlers — Good

---

## 🔐 Crypto-Wallet Specific Concerns

| Risk | Status | Notes |
|------|--------|-------|
| Private key exposure via XSS | ⚠️ HIGH RISK | No CSP = no XSS protection |
| Seed phrase capture by analytics | ⚠️ HIGH RISK | Contentsquare session replay active |
| Clipboard hijacking | ⚠️ MEDIUM RISK | No Permissions-Policy |
| Transaction manipulation via clickjacking | ⚠️ HIGH RISK | No X-Frame-Options |
| Cross-origin data theft | 🔴 CRITICAL | CORS: * allows any origin |
| Supply chain attack via CDN | ⚠️ MEDIUM RISK | Third-party JS, no SRI hashes |
| MITM downgrade | ⚠️ MEDIUM RISK | No HSTS |

---

## Remediation Priority

| Priority | Finding | Effort |
|----------|---------|--------|
| 🔴 P0 (Immediate) | F-01: Fix CORS wildcard | Low |
| 🔴 P0 (Immediate) | F-02: Implement CSP | Medium |
| 🟠 P1 (This week) | F-03: Add X-Frame-Options | Low |
| 🟠 P1 (This week) | F-05: Remove/isolate Contentsquare | Low |
| 🟠 P1 (This week) | F-07: Add HSTS | Low |
| 🟡 P2 (This sprint) | F-04: Add Permissions-Policy | Low |
| 🟡 P2 (This sprint) | F-08: Restrict dev subdomain | Medium |

---

## Limitations

- **Port scanning** was not possible due to sandbox restrictions (no raw socket permissions for nmap)
- **Dynamic analysis** (authenticated testing, JS source review) not performed in this phase
- **API endpoint testing** (api.novawallet.org) not in scope for this scan
- Cookie analysis limited — app uses no server-set cookies (likely localStorage/IndexedDB)

---

*Report generated by Edward @ 0xAudit | 2026-02-09*
