# 🛡️ Infrastructure & Network Audit — stratwise.ai

**Auditor:** Edward, 0xAudit  
**Date:** 2026-02-09  
**Scope:** DNS, Subdomains, Ports, Email Security, Cloud, WHOIS  

---

## 1. DNS Enumeration

| Record | Value |
|--------|-------|
| **A** | `104.21.31.201`, `172.67.179.239` (Cloudflare) |
| **AAAA** | `2606:4700:3031::6815:1fc9`, `2606:4700:3030::ac43:b3ef` |
| **NS** | `kristina.ns.cloudflare.com`, `kianchau.ns.cloudflare.com` |
| **MX** | `mx1.privateemail.com` (10), `mx2.privateemail.com` (10) |
| **SOA** | `kianchau.ns.cloudflare.com` |
| **CNAME** | None (root) |
| **TXT** | See below |

### TXT Records
- `firebase=stratwise-edaae`
- `hosting-site=stratwise-edaae`
- `v=spf1 include:_spf.firebasemail.com ~all`
- `v=spf1 include:spf.privateemail.com ~all`
- `google-site-verification=DdwWUkquGKORvqOiLoIHqzW70X3_gI8LFlGyMxoi8FM`

**Stack:** Cloudflare CDN → Firebase Hosting (stratwise-edaae) + Namecheap PrivateEmail

---

## 2. Subdomain Discovery

| Subdomain | Status | IPs |
|-----------|--------|-----|
| `www.stratwise.ai` | ✅ Active | Cloudflare proxy |
| `api.stratwise.ai` | ✅ Active | Cloudflare proxy → Returns JSON `404` with custom headers (`x-process-time`, `x-request-id`) — **backend API exists** |
| `app.stratwise.ai` | ✅ Active | Cloudflare proxy → Returns `403 Forbidden` |
| All others (admin, dashboard, staging, dev, test, mail, cdn, assets, docs, blog, beta, demo, portal) | ❌ NXDOMAIN | — |

### Key Observations
- `api.stratwise.ai` exposes backend headers: `access-control-allow-methods: GET, POST, PUT, PATCH, DELETE, OPTIONS` and `access-control-allow-credentials: true`
- `app.stratwise.ai` returns 403 — possibly restricted or under development

---

## 3. Port Scanning

All scanned ports on Cloudflare IPs returned closed (Cloudflare blocks non-HTTP). Only HTTP/HTTPS accessible via Cloudflare proxy. **nmap raw sockets unavailable in sandbox** — limited to bash connect scan.

Exposed services:
- **80/443** — HTTP/HTTPS via Cloudflare (confirmed via curl)
- No other ports accessible through Cloudflare

---

## 4. Cloudflare Bypass Analysis

| Vector | Result |
|--------|--------|
| MX Records | `mx1.privateemail.com` → `162.255.118.7` (Namecheap, NOT origin) |
| Firebase origin | `stratwise-edaae.firebaseapp.com` → `199.36.158.100` (Google Firebase) |
| Subdomains | All resolve to Cloudflare proxy |

**Conclusion:** Origin IP is well-protected. Firebase hosting is the actual origin (`199.36.158.100`), accessible directly at `stratwise-edaae.web.app` (returns 404 on root — content may be served differently).

---

## 5. Email Security

| Check | Status | Details |
|-------|--------|---------|
| **SPF** | ⚠️ WARNING | **Two conflicting SPF records** — `include:_spf.firebasemail.com ~all` AND `include:spf.privateemail.com ~all`. RFC 7208 mandates only ONE SPF record per domain. |
| **DKIM** | ❌ NOT FOUND | No DKIM records found for selectors: default, google, firebase, mail, s1, s2, k1 |
| **DMARC** | ❌ MISSING | No `_dmarc.stratwise.ai` TXT record exists |

---

## 6. Cloud Misconfiguration

| Service | URL | Status |
|---------|-----|--------|
| AWS S3 | `stratwise.s3.amazonaws.com` | 404 — bucket doesn't exist |
| Firebase RTDB | `stratwise-edaae.firebaseio.com/.json` | 404 — not configured or secured |
| Firebase Hosting | `stratwise-edaae.web.app` | 404 — accessible but no root content |

**Firebase project ID leaked:** `stratwise-edaae` (via TXT records)

---

## 7. WHOIS

WHOIS lookup unavailable (no `whois` binary in sandbox, API requires key). Domain registered via **Namecheap** (inferred from PrivateEmail MX and typical Cloudflare+Namecheap setup).

---

## Findings Summary

### FINDING 1: Missing DMARC Record
- **Severity:** HIGH
- **CVSS:** 7.4 (AV:N/AC:L/PR:N/UI:N/S:C/C:N/I:H/A:N)
- **Description:** No DMARC policy exists. Attackers can spoof emails from @stratwise.ai with no rejection policy, enabling phishing attacks against users/partners.
- **Recommendation:** Add `_dmarc.stratwise.ai TXT "v=DMARC1; p=reject; rua=mailto:dmarc@stratwise.ai; pct=100"`

### FINDING 2: Missing DKIM Records
- **Severity:** HIGH
- **CVSS:** 7.4 (AV:N/AC:L/PR:N/UI:N/S:C/C:N/I:H/A:N)
- **Description:** No DKIM signing configured. Email authenticity cannot be verified, increasing spoofing risk.
- **Recommendation:** Configure DKIM via Namecheap PrivateEmail and publish public keys in DNS.

### FINDING 3: Duplicate/Conflicting SPF Records
- **Severity:** MEDIUM
- **CVSS:** 5.3 (AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:L/A:N)
- **Description:** Two separate SPF records exist (Firebase + PrivateEmail). Per RFC 7208, only one SPF record is allowed. Receiving servers may fail SPF validation unpredictably.
- **Recommendation:** Merge into single record: `v=spf1 include:_spf.firebasemail.com include:spf.privateemail.com ~all`. Consider `-all` (hard fail) instead of `~all`.

### FINDING 4: Firebase Project ID Exposure
- **Severity:** LOW
- **CVSS:** 3.1 (AV:N/AC:H/PR:N/UI:N/S:U/C:L/I:N/A:N)
- **Description:** Firebase project ID `stratwise-edaae` is publicly visible in TXT records, enabling targeted attacks against Firebase services (Firestore rules, Cloud Functions, Auth).
- **Recommendation:** Ensure Firebase Security Rules are strict. This is informational — project IDs are semi-public by design, but should be combined with proper security rules audit.

### FINDING 5: Overly Permissive CORS on API
- **Severity:** MEDIUM
- **CVSS:** 5.4 (AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:L/A:N)
- **Description:** `api.stratwise.ai` returns `access-control-allow-credentials: true` with broad allowed methods (including DELETE). Combined with `access-control-allow-origin: *` on main domain, this could enable CSRF or data exfiltration if origin validation is weak.
- **Recommendation:** Restrict `Access-Control-Allow-Origin` to specific trusted domains. Never use `*` with `allow-credentials: true`.

### FINDING 6: SPF Soft Fail (~all)
- **Severity:** LOW
- **CVSS:** 3.7 (AV:N/AC:H/PR:N/UI:N/S:U/C:N/I:L/A:N)
- **Description:** SPF uses `~all` (soft fail) instead of `-all` (hard fail). Unauthorized senders' emails are marked but not rejected.
- **Recommendation:** After confirming all legitimate senders are included, change to `-all`.

---

## Risk Matrix

| # | Finding | Severity | CVSS |
|---|---------|----------|------|
| 1 | Missing DMARC | 🔴 HIGH | 7.4 |
| 2 | Missing DKIM | 🔴 HIGH | 7.4 |
| 3 | Duplicate SPF | 🟡 MEDIUM | 5.3 |
| 4 | Firebase ID exposure | 🟢 LOW | 3.1 |
| 5 | Overly permissive CORS | 🟡 MEDIUM | 5.4 |
| 6 | SPF soft fail | 🟢 LOW | 3.7 |

**Overall Infrastructure Risk: MEDIUM-HIGH**

---

## Architecture Summary

```
User → Cloudflare CDN (104.21.31.201 / 172.67.179.239)
         ├── stratwise.ai → Firebase Hosting (stratwise-edaae)
         ├── api.stratwise.ai → Backend API (unknown origin)
         ├── app.stratwise.ai → 403 (restricted)
         └── www.stratwise.ai → same as root
Email: Namecheap PrivateEmail (mx1/mx2.privateemail.com)
DNS: Cloudflare
```
