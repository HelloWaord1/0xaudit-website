# 🛡️ Web Application Security Audit — stratwise.ai

**Auditor:** Edward, 0xAudit  
**Date:** 2026-02-09  
**Target:** stratwise.ai  
**Classification:** CONFIDENTIAL  

---

## Executive Summary

Stratwise.ai is a React-based SPA (Vite build) behind Cloudflare CDN, serving an AI-powered crypto trading platform. The audit identified **8 findings** ranging from Medium to Informational severity. The most critical issues are overly permissive CORS, missing security headers, and exposed infrastructure subdomains.

---

## 1. Technology Stack

| Component | Details |
|-----------|---------|
| **CDN/WAF** | Cloudflare (cf-ray headers, NEL reporting) |
| **Frontend** | React SPA (Vite bundled: `/assets/index-BrVI2RJu.js`) |
| **SSL Issuer** | Google Trust Services (WE1), ECDSA P-256 |
| **SSL Validity** | 2026-01-30 → 2026-04-30 (90-day cert, likely auto-renewed) |
| **Analytics** | Google Tag Manager (GTM-P29T4RP7) |
| **PWA** | manifest.json present, standalone mode |
| **Backend (api)** | Cloudflare-proxied, returns JSON |
| **Monitoring** | Grafana instance at grafana.stratwise.ai (nginx/1.18.0 Ubuntu) |
| **QA API** | qa.api.stratwise.ai (nginx/1.24.0 Ubuntu) |

---

## 2. Subdomains Discovered (via crt.sh)

| Subdomain | Status | Notes |
|-----------|--------|-------|
| stratwise.ai | 200 | Main site |
| app.stratwise.ai | 403 | Blocked (Cloudflare) |
| api.stratwise.ai | 404 | API endpoint, active |
| auth.stratwise.ai | 404 | Has HSTS! |
| grafana.stratwise.ai | 302 | **Grafana exposed** (nginx/1.18.0) |
| qa.api.stratwise.ai | 404 | **QA API exposed** (nginx/1.24.0) |
| affiliate.stratwise.ai | 502 | Down |
| www.stratwise.ai | 522 | Origin unreachable |
| *.stratwise.ai | — | Wildcard cert exists |

---

## 3. Open Ports (Cloudflare IPs: 104.21.31.201, 172.67.179.239)

| Port | State | Service |
|------|-------|---------|
| 80 | Open | HTTP |
| 443 | Open | HTTPS |
| 8080 | Open | HTTP Proxy |
| 8443 | Open | HTTPS Alt (serves same content) |

---

## 4. Findings

### F-01: Overly Permissive CORS — `Access-Control-Allow-Origin: *`

| | |
|---|---|
| **Severity** | 🟠 MEDIUM |
| **CVSS 3.1** | **5.3** (AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N) |
| **Header** | `access-control-allow-origin: *` |
| **Impact** | Any origin can read responses from this domain. For a **financial trading platform**, this enables cross-origin data theft if any authenticated endpoints share this policy. Attackers can exfiltrate user data, trading strategies, or session tokens via malicious websites. |
| **Recommendation** | Replace `*` with explicit allowed origins (e.g., `https://app.stratwise.ai`). Implement `Access-Control-Allow-Credentials` only with specific origins, never with `*`. |

---

### F-02: Missing Content-Security-Policy (CSP) Header

| | |
|---|---|
| **Severity** | 🟠 MEDIUM |
| **CVSS 3.1** | **5.4** (AV:N/AC:L/PR:N/UI:R/S:U/C:L/I:L/A:N) |
| **Finding** | No `Content-Security-Policy` header present |
| **Impact** | Without CSP, the application is vulnerable to XSS payload execution, inline script injection, and data exfiltration. GTM injection further increases attack surface. |
| **Recommendation** | Implement strict CSP: `default-src 'self'; script-src 'self' https://www.googletagmanager.com; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self' https://api.stratwise.ai` |

---

### F-03: Missing Strict-Transport-Security (HSTS) Header

| | |
|---|---|
| **Severity** | 🟠 MEDIUM |
| **CVSS 3.1** | **4.8** (AV:N/AC:H/PR:N/UI:R/S:U/C:L/I:L/A:N) |
| **Finding** | No `Strict-Transport-Security` header on main domain (note: auth.stratwise.ai HAS it) |
| **Impact** | Users can be downgraded to HTTP via MITM, enabling session hijacking and credential theft. Critical for a financial platform. |
| **Recommendation** | Add `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`. Submit to HSTS preload list. |

---

### F-04: Missing X-Frame-Options Header

| | |
|---|---|
| **Severity** | 🟡 LOW |
| **CVSS 3.1** | **4.3** (AV:N/AC:L/PR:N/UI:R/S:U/C:N/I:L/A:N) |
| **Finding** | No `X-Frame-Options` header |
| **Impact** | Site can be embedded in iframes on malicious sites, enabling clickjacking attacks. Attacker could trick users into executing trades or changing settings. |
| **Recommendation** | Add `X-Frame-Options: DENY` or use CSP `frame-ancestors 'none'` |

---

### F-05: Missing Permissions-Policy Header

| | |
|---|---|
| **Severity** | 🟡 LOW |
| **CVSS 3.1** | **3.1** (AV:N/AC:H/PR:N/UI:R/S:U/C:L/I:N/A:N) |
| **Finding** | No `Permissions-Policy` header |
| **Impact** | Browser features (camera, microphone, geolocation) not explicitly restricted. Third-party scripts (GTM) could access these APIs. |
| **Recommendation** | Add `Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=()` |

---

### F-06: Grafana Instance Publicly Accessible

| | |
|---|---|
| **Severity** | 🟠 MEDIUM |
| **CVSS 3.1** | **5.3** (AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N) |
| **Finding** | `grafana.stratwise.ai` responds with 302 redirect, running nginx/1.18.0 on Ubuntu |
| **Impact** | Monitoring dashboards may expose infrastructure metrics, server health, error rates, and internal architecture. Default credentials or known Grafana CVEs could grant access. nginx/1.18.0 is outdated. |
| **Recommendation** | Restrict Grafana behind VPN/IP allowlist. Update nginx to latest. Ensure strong authentication and no default admin/admin credentials. |

---

### F-07: QA/Staging API Publicly Accessible

| | |
|---|---|
| **Severity** | 🟡 LOW |
| **CVSS 3.1** | **4.3** (AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N) |
| **Finding** | `qa.api.stratwise.ai` is publicly reachable (nginx/1.24.0), returns 404 JSON |
| **Impact** | QA environments often have weaker security, debug endpoints, or test data. Server version disclosure (nginx/1.24.0) aids reconnaissance. |
| **Recommendation** | Move QA environment behind VPN. Remove DNS record if unused. Disable server version disclosure. |

---

### F-08: No Cookies Observed (Informational)

| | |
|---|---|
| **Severity** | ℹ️ INFO |
| **CVSS 3.1** | **N/A** |
| **Finding** | No `Set-Cookie` headers observed on initial page load |
| **Note** | SPA likely handles auth via localStorage/sessionStorage JWT tokens. This shifts security responsibility to JavaScript — ensure tokens aren't accessible to XSS (relates to F-02 CSP missing). |

---

## 5. Positive Findings ✅

| Header/Feature | Status |
|----------------|--------|
| `referrer-policy: strict-origin-when-cross-origin` | ✅ Present |
| `x-content-type-options: nosniff` | ✅ Present |
| SSL/TLS (ECDSA P-256, TLS 1.3 via Cloudflare) | ✅ Strong |
| Certificate validity | ✅ Valid, auto-renewed |
| Cloudflare WAF/DDoS protection | ✅ Active |
| robots.txt AI training restrictions | ✅ Configured |
| No server version leak on main domain | ✅ Cloudflare masks it |

---

## 6. Risk Summary

| Severity | Count |
|----------|-------|
| 🔴 Critical | 0 |
| 🟠 Medium | 4 |
| 🟡 Low | 3 |
| ℹ️ Info | 1 |

**Overall Risk Rating: MEDIUM**

---

## 7. Priority Remediation Roadmap

1. **Immediate** — Fix CORS policy (F-01): Replace `*` with specific origins
2. **Immediate** — Add HSTS header (F-03): Critical for financial platform
3. **This week** — Implement CSP (F-02): Protect against XSS
4. **This week** — Restrict Grafana & QA access (F-06, F-07): VPN/IP allowlist
5. **Next sprint** — Add X-Frame-Options (F-04) and Permissions-Policy (F-05)

---

*Report generated by Edward @ 0xAudit | 2026-02-09*
