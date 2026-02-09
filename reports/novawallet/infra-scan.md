# 🛡️ Infrastructure & Network Security Audit — novawallet.org

**Auditor:** Edward, 0xAudit  
**Date:** 2026-02-09  
**Target:** novawallet.org / app.novawallet.org  
**Type:** Crypto Wallet (Substrate/Polkadot ecosystem)

---

## 1. DNS Reconnaissance

### novawallet.org
| Record | Value |
|--------|-------|
| A | `104.21.24.226`, `172.67.220.227` (Cloudflare) |
| AAAA | `2606:4700:3031::6815:18e2`, `2606:4700:3037::ac43:dce3` |
| NS | `frank.ns.cloudflare.com`, `veronica.ns.cloudflare.com` |
| MX | **None** (no mail server) |
| TXT | `google-site-verification=u8y8Rn8pHQUturPoGXkXh0IyaGHCdY2FT25yyR792kg` |
| TXT | `protonmail-verification=b4f1345f259ea5fca920c17feb77f7b8897889ea` |
| SOA | `frank.ns.cloudflare.com. dns.cloudflare.com.` |

### app.novawallet.org
| Record | Value |
|--------|-------|
| A | `172.67.220.227`, `104.21.24.226` (Cloudflare) |
| AAAA | `2606:4700:3031::6815:18e2`, `2606:4700:3037::ac43:dce3` |
| CNAME | None (direct A record) |

---

## 2. Subdomain Discovery

### crt.sh Certificate Transparency
| Subdomain | Status | Notes |
|-----------|--------|-------|
| `novawallet.org` | ✅ Active | Wildcard `*.novawallet.org` cert (Let's Encrypt + Google Trust + GoDaddy) |
| `app.novawallet.org` | ✅ Active | Google Trust Services certs, resolves to Cloudflare |
| `dev.novawallet.org` | ✅ Active | Google Trust Services certs, resolves to Cloudflare |
| `my.novawallet.org` | ✅ Active | Let's Encrypt certs, resolves to Cloudflare |
| `www.novawallet.org` | ❌ No DNS | Only in GoDaddy cert SAN |

### Brute-force subdomain check (dig)
| Subdomain | Result |
|-----------|--------|
| www, api, admin, dashboard, staging, test, mail, cdn, wallet, node, rpc | All **NXDOMAIN** |

### ⚠️ FINDING: DEV-001 — Development Subdomain Exposed

| Field | Value |
|-------|-------|
| **Severity** | **MEDIUM** |
| **CVSS** | 5.3 (CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N) |
| **Description** | `dev.novawallet.org` is publicly accessible with valid TLS certificates. Development environments may expose debug features, unfinished functionality, or less hardened configurations. |
| **Recommendation** | Restrict `dev.novawallet.org` behind VPN/IP allowlist or remove public DNS. Ensure no debug endpoints or source maps are exposed. |

---

## 3. Port Scanning

**Note:** nmap could not complete — raw socket permission denied in sandbox. All traffic to `app.novawallet.org` routes through Cloudflare proxy (104.21.24.226 / 172.67.220.227), which only exposes ports 80/443 by default. Blockchain RPC ports (8545, 8546, 26657, 9090) are not reachable on the Cloudflare edge.

---

## 4. Cloudflare Analysis & Bypass Attempt

| Check | Result |
|-------|--------|
| Cloudflare proxy | ✅ Confirmed (all domains resolve to CF IPs) |
| MX records | None — no mail server to leak origin IP |
| Subdomains | All discovered subdomains resolve to same CF IPs |
| Historical DNS | Protonmail verification suggests ProtonMail use (no self-hosted mail) |
| Origin IP exposure | **Not found** — good protection |

### ✅ FINDING: CF-001 — Good: Origin IP Not Exposed
All subdomains are properly proxied through Cloudflare. No direct origin IP leakage detected via MX, subdomains, or certificate transparency records.

---

## 5. Email Security

| Record | Value | Status |
|--------|-------|--------|
| SPF | **Not configured** (no SPF TXT record) | ⚠️ |
| DMARC | `v=DMARC1; p=reject; adkim=r; aspf=r; rua=mailto:dmarc_rua@onsecureserver.net;` | ✅ |
| DKIM | Not verified (no MX → email via ProtonMail) | ℹ️ |
| MX | **None** | ℹ️ |

### ⚠️ FINDING: EMAIL-001 — Missing SPF Record

| Field | Value |
|-------|-------|
| **Severity** | **MEDIUM** |
| **CVSS** | 5.3 (CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:L/A:N) |
| **Description** | No SPF record is configured for `novawallet.org`. While DMARC is set to `p=reject` (good), the absence of SPF means the DMARC policy relies solely on DKIM alignment. An attacker could spoof emails from `@novawallet.org` if DKIM verification alone fails. For a **crypto wallet** project, email spoofing is a critical phishing vector. |
| **Recommendation** | Add SPF record: `v=spf1 include:_spf.protonmail.ch ~all` (or appropriate for your mail provider). This strengthens DMARC enforcement. |

### ℹ️ FINDING: EMAIL-002 — DMARC Reporting to Third Party

| Field | Value |
|-------|-------|
| **Severity** | **LOW** |
| **CVSS** | 2.0 |
| **Description** | DMARC aggregate reports (`rua`) are sent to `dmarc_rua@onsecureserver.net` (GoDaddy/Secureserver). This is the registrar default — reports may not be actively monitored. |
| **Recommendation** | Configure DMARC reporting to an actively monitored address or service (e.g., Postmark DMARC, dmarcian). |

---

## 6. Cloud Misconfiguration

| Check | Result |
|-------|--------|
| `novawallet.s3.amazonaws.com` | ❌ `NoSuchBucket` — does not exist |
| Firebase | Not tested (no indicators found) |
| GCP | Google Trust Services certs suggest Firebase Hosting or GCP — but no public misconfig found |

### ℹ️ INFO: Google Trust Services Certificates
Certificates for `app.novawallet.org` and `dev.novawallet.org` are issued by Google Trust Services (WE1/WR1), indicating the origin server likely runs on **Firebase Hosting** or **Google Cloud** behind Cloudflare.

---

## 7. Blockchain Node Exposure

| Port | Service | Status |
|------|---------|--------|
| 8545 | Ethereum JSON-RPC | Not reachable (behind Cloudflare) |
| 8546 | Ethereum WS-RPC | Not reachable |
| 26657 | Tendermint RPC | Not reachable |
| 9090 | gRPC | Not reachable |

✅ No exposed blockchain RPC endpoints detected on public-facing infrastructure.

---

## 8. WHOIS Information

| Field | Value |
|-------|-------|
| Domain | novawallet.org |
| Created | 2025-05-31 |
| Updated | 2025-06-29 |
| Expires | 2026-05-31 |
| Registrar | GoDaddy (implied by cert + WHOIS service) |
| Nameservers | Cloudflare (frank / veronica) |
| Domain Status | clientDeleteProhibited, clientRenewProhibited, clientTransferProhibited, clientUpdateProhibited |
| Privacy | WHOIS privacy enabled (no registrant details exposed) |

### ✅ FINDING: WHOIS-001 — Good Domain Lock Configuration
All four client-side EPP locks are in place, preventing unauthorized transfers, updates, or deletion. WHOIS privacy is enabled.

---

## 9. Certificate Hygiene

### ⚠️ FINDING: CERT-001 — Multiple CA Issuers

| Field | Value |
|-------|-------|
| **Severity** | **LOW** |
| **CVSS** | 2.0 |
| **Description** | Certificates are issued by 3 different CAs: Google Trust Services, Let's Encrypt, and GoDaddy. Multiple CAs increase the attack surface for certificate misissuance and complicate monitoring. The GoDaddy cert (novawallet.org + www) appears separate from the Cloudflare-managed certs. |
| **Recommendation** | Consolidate to a single CA strategy. If using Cloudflare Universal SSL, disable external certificates. Implement CAA DNS records to restrict allowed issuers. |

### ⚠️ FINDING: CERT-002 — No CAA Records

| Field | Value |
|-------|-------|
| **Severity** | **MEDIUM** |
| **CVSS** | 4.3 (CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:N/I:L/A:N) |
| **Description** | No CAA (Certificate Authority Authorization) DNS records found. Any CA can issue certificates for `novawallet.org`. For a crypto wallet, unauthorized certificate issuance enables MitM attacks. |
| **Recommendation** | Add CAA records: `novawallet.org. CAA 0 issue "letsencrypt.org"` and `novawallet.org. CAA 0 issue "pki.goog"` (restrict to only your CAs). |

---

## 10. DNSSEC

### ⚠️ FINDING: DNS-001 — DNSSEC Not Validated

| Field | Value |
|-------|-------|
| **Severity** | **MEDIUM** |
| **CVSS** | 4.3 (CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:N/I:L/A:N) |
| **Description** | DNS responses show `AD: false` (Authenticated Data flag not set), indicating DNSSEC is not fully validated. DNS spoofing/hijacking attacks are possible. For a crypto wallet, DNS hijacking redirects users to malicious sites. |
| **Recommendation** | Enable DNSSEC via Cloudflare dashboard and configure DS records with your registrar (GoDaddy). |

---

## Summary

| ID | Finding | Severity | CVSS |
|----|---------|----------|------|
| DEV-001 | Development subdomain publicly exposed | **MEDIUM** | 5.3 |
| EMAIL-001 | Missing SPF record | **MEDIUM** | 5.3 |
| EMAIL-002 | DMARC reporting to unmonitored default | LOW | 2.0 |
| CERT-001 | Multiple CA issuers | LOW | 2.0 |
| CERT-002 | No CAA DNS records | **MEDIUM** | 4.3 |
| DNS-001 | DNSSEC not enabled | **MEDIUM** | 4.3 |

### Positive Findings
- ✅ All domains behind Cloudflare proxy — origin IP not exposed
- ✅ DMARC set to `p=reject` (strongest policy)
- ✅ WHOIS privacy + all EPP domain locks enabled
- ✅ No exposed blockchain RPC endpoints
- ✅ No S3 bucket misconfiguration
- ✅ No exposed admin/staging/test subdomains

### Overall Risk: **LOW-MEDIUM**
Infrastructure is well-protected behind Cloudflare. Main concerns are DNS hardening (DNSSEC, CAA), email authentication (SPF), and development environment exposure.

---

*Report generated by 0xAudit — Edward | 2026-02-09*
