# Installed Security Tools

**Date:** 2026-02-09
**Environment:** Linux x86_64, Node.js v22, Python 3.11.2

## Tool Status

| # | Tool | Status | Version | Binary Path | Notes |
|---|------|--------|---------|-------------|-------|
| 1 | **Nuclei** | ✅ installed | v3.7.0 | `/usr/local/bin/nuclei` | ProjectDiscovery vuln scanner |
| 2 | **Nikto** | ✅ installed | v2.5.0 | `/opt/nikto/program/nikto.pl` | Git clone, no SSL support |
| 3 | **sqlmap** | ✅ installed | 1.10.2 | `sqlmap` (pip) | SQL injection testing |
| 4 | **subfinder** | ✅ installed | v2.12.0 | `/usr/local/bin/subfinder` | Subdomain discovery |
| 5 | **httpx** (PD) | ✅ installed | v1.8.1 | `/usr/local/bin/pd-httpx` | Renamed to avoid pip conflict |
| 6 | **ffuf** | ✅ installed | v2.1.0 | `/usr/local/bin/ffuf` | Web fuzzer |
| 7 | **semgrep** | ✅ installed | 1.151.0 | `semgrep` (pip) | Static code analysis |
| 8 | **trivy** | ✅ installed | 0.69.1 | `/usr/local/bin/trivy` | Container/dependency scanner |

## Quick Reference

```bash
# Vulnerability scanning
nuclei -u https://target.com -t http/

# Web server scanning
perl /opt/nikto/program/nikto.pl -h https://target.com

# SQL injection
sqlmap -u "https://target.com/page?id=1" --batch

# Subdomain enumeration
subfinder -d target.com

# HTTP probing
pd-httpx -l urls.txt

# Web fuzzing
ffuf -u https://target.com/FUZZ -w /path/to/wordlist

# Code analysis
semgrep scan --config auto /path/to/code

# Dependency scanning
trivy fs /path/to/project
```

## Notes
- **httpx conflict**: ProjectDiscovery httpx renamed to `pd-httpx` because pip's `httpx` (Python HTTP library, installed as semgrep dependency) takes the same name
- **Nikto**: No SSL support in this environment (missing perl SSL modules). Use `--nossl` or install `libnet-ssleay-perl`
- All 8/8 tools installed successfully
